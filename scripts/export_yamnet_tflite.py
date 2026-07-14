import tensorflow as tf
import tensorflow_hub as hub
import numpy as np

TARGET_SR = 16000
MAX_SAMPLES = 48000

print("Loading YAMNet from TF Hub...")
yamnet = hub.load("https://tfhub.dev/google/yamnet/1")

print("Building concrete function with fixed input shape...")
@tf.function(input_signature=[
    tf.TensorSpec(shape=[MAX_SAMPLES], dtype=tf.float32, name="waveform")
])
def yamnet_tflite(waveform):
    scores, embeddings, log_mel = yamnet(waveform)
    return {"embeddings": embeddings}

converter = tf.lite.TFLiteConverter.from_concrete_functions(
    [yamnet_tflite.get_concrete_function()], yamnet_tflite
)

print("Optimizing for size (quantization)...")
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]

print("Converting...")
tflite_model = converter.convert()

out_path = "/home/carine/voxcordis/voxcordis_app/assets/models/yamnet_quantized.tflite"
with open(out_path, "wb") as f:
    f.write(tflite_model)

print(f"Written {len(tflite_model)} bytes to {out_path}")

interp = tf.lite.Interpreter(model_content=tflite_model)
interp.allocate_tensors()
for d in interp.get_input_details():
    print(f"Input: {d['name']} shape={d['shape']} dtype={d['dtype']}")
for d in interp.get_output_details():
    print(f"Output: {d['name']} shape={d['shape']} dtype={d['dtype']}")

test_input = np.random.randn(MAX_SAMPLES).astype(np.float32)
interp.set_tensor(interp.get_input_details()[0]['index'], test_input)
interp.invoke()
emb = interp.get_tensor(interp.get_output_details()[0]['index'])
print(f"Test OK: embedding shape={emb.shape}")
