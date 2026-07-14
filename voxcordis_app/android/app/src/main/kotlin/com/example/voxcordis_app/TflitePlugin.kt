package com.example.voxcordis_app

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.Interpreter
import java.nio.ByteBuffer
import java.nio.ByteOrder

class TflitePlugin(private val context: Context) {
    private var yamnet: Interpreter? = null
    private var classifier: Interpreter? = null

    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadModels" -> loadModels(result)
            "runYamnet" -> runYamnet(call, result)
            "runClassifier" -> runClassifier(call, result)
            "close" -> close(result)
            else -> result.notImplemented()
        }
    }

    private fun loadModels(result: MethodChannel.Result) {
        try {
            yamnet = Interpreter(loadModelFile("flutter_assets/assets/models/yamnet_quantized.tflite"))
            classifier = Interpreter(loadModelFile("flutter_assets/assets/models/voxcordis_model.tflite"))

            val yIn = yamnet!!.getInputTensor(0)
            val yOut = yamnet!!.getOutputTensor(0)
            Log.i("TFLite", "YAMNet input shape=[${yIn.shape().joinToString()}] type=${yIn.dataType()}")
            Log.i("TFLite", "YAMNet output[0] shape=[${yOut.shape().joinToString()}] type=${yOut.dataType()}")

            val cIn = classifier!!.getInputTensor(0)
            val cOut = classifier!!.getOutputTensor(0)
            Log.i("TFLite", "Classifier input shape=[${cIn.shape().joinToString()}] type=${cIn.dataType()}")
            Log.i("TFLite", "Classifier output shape=[${cOut.shape().joinToString()}] type=${cOut.dataType()}")

            result.success(true)
        } catch (e: Exception) {
            Log.e("TFLite", "loadModels error", e)
            result.error("LOAD_ERROR", e.message, null)
        }
    }

    private fun loadModelFile(name: String): ByteBuffer {
        return context.assets.open(name).use { stream ->
            val bytes = stream.readBytes()
            ByteBuffer.allocateDirect(bytes.size).apply {
                put(bytes)
                rewind()
                order(ByteOrder.nativeOrder())
            }
        }
    }

    private fun runYamnet(call: MethodCall, result: MethodChannel.Result) {
        try {
            val samples = (call.argument<List<Double>>("samples") ?: error("missing samples"))
                .map { it.toFloat() }.toFloatArray()
            val yamnet = this.yamnet ?: error("YAMNet not loaded")

            val inTensor = yamnet.getInputTensor(0)
            val outTensor = yamnet.getOutputTensor(0)

            val inputBuf = quantizeInput(samples, inTensor)
            val outShape = outTensor.shape()
            val outSize = outShape.fold(1) { a, b -> a * b }
            val outBuf = ByteBuffer.allocateDirect(
                if (outTensor.dataType() == org.tensorflow.lite.DataType.UINT8) outSize else outSize * 4
            )

            yamnet.run(inputBuf, outBuf)

            val mean = meanEmbedding(outBuf, outTensor)
            result.success(mean.map { it.toDouble() })
        } catch (e: Exception) {
            Log.e("TFLite", "runYamnet error", e)
            result.error("YAMNET_ERROR", e.message, null)
        }
    }

    private fun runClassifier(call: MethodCall, result: MethodChannel.Result) {
        try {
            val embedding = (call.argument<List<Double>>("embedding") ?: error("missing embedding"))
                .map { it.toFloat() }.toFloatArray()
            val classifier = this.classifier ?: error("Classifier not loaded")

            val inTensor = classifier.getInputTensor(0)
            val outTensor = classifier.getOutputTensor(0)
            val inputBuf = quantizeInput(embedding, inTensor)

            val outShape = outTensor.shape()
            val outSize = outShape.fold(1) { a, b -> a * b }
            val outBuf = ByteBuffer.allocateDirect(
                if (outTensor.dataType() == org.tensorflow.lite.DataType.UINT8) outSize else outSize * 4
            )

            classifier.run(inputBuf, outBuf)

            val output = dequantizeOutput(outBuf, outTensor)
            result.success(output.map { it.toDouble() })
        } catch (e: Exception) {
            Log.e("TFLite", "runClassifier error", e)
            result.error("CLASSIFIER_ERROR", e.message, null)
        }
    }

    private fun quantizeInput(samples: FloatArray, tensor: org.tensorflow.lite.Tensor): ByteBuffer {
        if (tensor.dataType() == org.tensorflow.lite.DataType.UINT8) {
            val q = tensor.quantizationParams()
            return ByteBuffer.allocateDirect(samples.size).apply {
                for (s in samples) {
                    val qv = (s / q.scale + q.zeroPoint).toInt().coerceIn(0, 255)
                    put(qv.toByte())
                }
                rewind()
            }
        }
        return ByteBuffer.allocateDirect(samples.size * 4).apply {
            order(ByteOrder.nativeOrder())
            asFloatBuffer().put(samples)
            rewind()
        }
    }

    private fun dequantizeOutput(buf: ByteBuffer, tensor: org.tensorflow.lite.Tensor): FloatArray {
        val shape = tensor.shape()
        val size = shape.fold(1) { a, b -> a * b }
        val result = FloatArray(size)

        if (tensor.dataType() == org.tensorflow.lite.DataType.UINT8) {
            val q = tensor.quantizationParams()
            val bytes = ByteArray(size)
            buf.rewind(); buf.get(bytes)
            for (i in 0 until size) {
                result[i] = ((bytes[i].toInt() and 0xFF) - q.zeroPoint).toFloat() * q.scale
            }
        } else {
            buf.rewind()
            val fb = buf.asFloatBuffer()
            for (i in 0 until size) {
                result[i] = fb.get(i)
            }
        }
        return result
    }

    private fun meanEmbedding(buf: ByteBuffer, tensor: org.tensorflow.lite.Tensor): FloatArray {
        val shape = tensor.shape()
        val embSize = shape.last()
        val nFrames = if (shape.size >= 2) shape[0] else 1
        val flat = dequantizeOutput(buf, tensor)
        val mean = FloatArray(embSize)
        for (f in 0 until nFrames) {
            for (i in 0 until embSize) {
                mean[i] += flat[f * embSize + i] / nFrames
            }
        }
        return mean
    }

    private fun close(result: MethodChannel.Result) {
        yamnet?.close(); yamnet = null
        classifier?.close(); classifier = null
        result.success(true)
    }
}
