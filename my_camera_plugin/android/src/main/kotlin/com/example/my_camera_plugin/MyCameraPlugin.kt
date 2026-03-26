package com.example.my_camera_plugin

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.provider.MediaStore
import android.util.Base64
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream

class MyCameraPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private lateinit var channel : MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private val CAMERA_REQUEST_ID = 9999

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "my_camera_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "openCamera") {
            if (activity != null) {
                pendingResult = result
                val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
                activity!!.startActivityForResult(intent, CAMERA_REQUEST_ID)
            } else {
                result.error("NO_ACTIVITY", "Activity is null", null)
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == CAMERA_REQUEST_ID) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val bitmap = data.extras?.get("data") as? Bitmap
                if (bitmap != null) {
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream)
                    val byteArray = stream.toByteArray()
                    val base64Image = Base64.encodeToString(byteArray, Base64.NO_WRAP)
                    pendingResult?.success(base64Image)
                } else {
                    pendingResult?.success(null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
            return true
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }
    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }
    override fun onDetachedFromActivity() { activity = null }
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}