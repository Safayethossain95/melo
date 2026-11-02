package com.melo.app.melo

import android.content.Context
import android.content.Intent
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.melo.app/audio_output"
    private var methodChannel: MethodChannel? = null
    private var audioDeviceCallback: AudioDeviceCallback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager

            when (call.method) {
                "getAppStoragePath" -> {
                    result.success(applicationContext.filesDir.absolutePath)
                }
                "getAudioOutputs" -> {
                    if (audioManager == null) {
                        result.error("UNAVAILABLE", "AudioManager not available", null)
                        return@setMethodCallHandler
                    }
                    val outputs = getConnectedOutputs(audioManager)
                    result.success(outputs)
                }
                "getCurrentOutput" -> {
                    if (audioManager == null) {
                        result.error("UNAVAILABLE", "AudioManager not available", null)
                        return@setMethodCallHandler
                    }
                    val current = getCurrentActiveOutput(audioManager)
                    result.success(current)
                }
                "switchToSpeaker" -> {
                    if (audioManager == null) {
                        result.error("UNAVAILABLE", "AudioManager not available", null)
                        return@setMethodCallHandler
                    }
                    try {
                        routeToSpeaker(audioManager)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "switchToDevice" -> {
                    if (audioManager == null) {
                        result.error("UNAVAILABLE", "AudioManager not available", null)
                        return@setMethodCallHandler
                    }
                    val deviceId = call.argument<Int>("id")
                    try {
                        if (deviceId != null) {
                            routeToDevice(audioManager, deviceId)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "openOutputSettings" -> {
                    openMediaOutputSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        registerAudioListener()
    }

    private fun registerAudioListener() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
            audioDeviceCallback = object : AudioDeviceCallback() {
                override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>?) {
                    notifyOutputsChanged()
                }

                override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>?) {
                    notifyOutputsChanged()
                }
            }
            audioManager.registerAudioDeviceCallback(audioDeviceCallback, null)
        }
    }

    private fun notifyOutputsChanged() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        val current = getCurrentActiveOutput(audioManager)
        val all = getConnectedOutputs(audioManager)
        runOnUiThread {
            methodChannel?.invokeMethod(
                "onOutputsChanged",
                mapOf(
                    "current" to current,
                    "available" to all
                )
            )
        }
    }

    private fun getConnectedOutputs(audioManager: AudioManager): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (dev in devices) {
                val typeStr = when (dev.type) {
                    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                    AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
                    26 /* TYPE_BLE_HEADSET */,
                    27 /* TYPE_BLE_SPEAKER */ -> "bluetooth"

                    AudioDeviceInfo.TYPE_WIRED_HEADSET,
                    AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                    AudioDeviceInfo.TYPE_USB_HEADSET -> "wired"

                    AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "speaker"
                    else -> continue
                }

                val rawName = dev.productName?.toString()?.trim()
                val name = if (!rawName.isNullOrEmpty()) {
                    rawName
                } else {
                    when (typeStr) {
                        "bluetooth" -> "Bluetooth Audio Device"
                        "wired" -> "Wired Headphones"
                        else -> "Phone Speaker"
                    }
                }

                list.add(
                    mapOf(
                        "id" to dev.id,
                        "name" to name,
                        "type" to typeStr
                    )
                )
            }
        }

        if (list.none { it["type"] == "speaker" }) {
            list.add(
                mapOf(
                    "id" to 0,
                    "name" to "Phone Speaker",
                    "type" to "speaker"
                )
            )
        }
        return list
    }

    private fun getCurrentActiveOutput(audioManager: AudioManager): Map<String, Any> {
        val outputs = getConnectedOutputs(audioManager)

        // If communication device is set (e.g. routed to speaker or specific device)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val commDevice = audioManager.communicationDevice
            if (commDevice != null) {
                val match = outputs.find { it["id"] == commDevice.id }
                if (match != null) return match
            }
        }

        if (audioManager.isSpeakerphoneOn) {
            val speaker = outputs.find { it["type"] == "speaker" }
            if (speaker != null) return speaker
        }

        // Check if any Bluetooth output device is connected
        val bluetooth = outputs.find { it["type"] == "bluetooth" }
        if (bluetooth != null && audioManager.isBluetoothA2dpOn) {
            return bluetooth
        }

        val wired = outputs.find { it["type"] == "wired" }
        if (wired != null && audioManager.isWiredHeadsetOn) {
            return wired
        }

        // If bluetooth is connected, it has natural priority
        if (bluetooth != null) return bluetooth
        if (wired != null) return wired

        return outputs.find { it["type"] == "speaker" } ?: mapOf(
            "id" to 0,
            "name" to "Phone Speaker",
            "type" to "speaker"
        )
    }

    private fun routeToSpeaker(audioManager: AudioManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            val speaker = devices.find { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
            if (speaker != null) {
                audioManager.setCommunicationDevice(speaker)
            }
        }
        audioManager.isSpeakerphoneOn = true
        notifyOutputsChanged()
    }

    private fun routeToDevice(audioManager: AudioManager, deviceId: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            val target = devices.find { it.id == deviceId }
            if (target != null) {
                if (target.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER) {
                    audioManager.setCommunicationDevice(target)
                    audioManager.isSpeakerphoneOn = true
                } else {
                    audioManager.clearCommunicationDevice()
                    audioManager.isSpeakerphoneOn = false
                    audioManager.setCommunicationDevice(target)
                }
            }
        } else {
            audioManager.isSpeakerphoneOn = false
        }
        notifyOutputsChanged()
    }

    private fun openMediaOutputSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val intent = Intent("android.settings.panel.action.MEDIA_OUTPUT")
                intent.putExtra("com.android.settings.panel.extra.PACKAGE_NAME", packageName)
                startActivity(intent)
                return
            }
        } catch (_: Exception) {}

        try {
            val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
            startActivity(intent)
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && audioDeviceCallback != null) {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            audioManager?.unregisterAudioDeviceCallback(audioDeviceCallback)
        }
        super.onDestroy()
    }
}
