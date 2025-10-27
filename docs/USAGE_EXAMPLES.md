# ?? Usage Examples - What You Can Build with ROCm

After installing ROCm with this installer, here are real-world examples of what you can build and run on your AMD GPU.

---

## ?? Stable Diffusion - Image Generation

### ComfyUI Setup
```bash
# In WSL2
cd ~
git clone https://github.com/comfyanonymous/ComfyUI
cd ComfyUI

# IMPORTANT: Edit requirements.txt - comment out torch line
sed -i 's/^torch/#torch/' requirements.txt

# Install dependencies
pip install -r requirements.txt

# Download models
cd models/checkpoints
wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors

# Run ComfyUI
cd ~/ComfyUI
python main.py --listen 0.0.0.0 --port 8188
```

Access at: http://localhost:8188

### Automatic1111 Web UI
```bash
cd ~
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui
cd stable-diffusion-webui

# Skip torch installation
export TORCH_COMMAND="pip install torch torchvision --no-deps"

# Launch
./webui.sh --listen --api
```

Access at: http://localhost:7860

---

## ?? Large Language Models (LLMs)

### Hugging Face Transformers
```python
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

# Load a model (e.g., GPT-2)
model_name = "gpt2"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name)

# Move to GPU
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = model.to(device)

# Generate text
input_text = "Once upon a time"
inputs = tokenizer(input_text, return_tensors="pt").to(device)

outputs = model.generate(
    inputs["input_ids"],
    max_length=100,
    temperature=0.7,
    do_sample=True
)

generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
print(generated_text)
```

### LLaMA 2 with Transformers
```python
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

# Requires HuggingFace account and LLaMA access
model_name = "meta-llama/Llama-2-7b-chat-hf"

tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.float16,
    device_map="auto"
)

# Chat interface
def chat(prompt):
    inputs = tokenizer(prompt, return_tensors="pt").to("cuda")
    outputs = model.generate(
        **inputs,
        max_new_tokens=256,
temperature=0.7,
   top_p=0.9
    )
  return tokenizer.decode(outputs[0], skip_special_tokens=True)

# Example usage
response = chat("What is the capital of France?")
print(response)
```

### Text Generation WebUI (Oobabooga)
```bash
cd ~
git clone https://github.com/oobabooga/text-generation-webui
cd text-generation-webui

# Install
pip install -r requirements.txt

# Download a model
python download-model.py TheBloke/Llama-2-7B-GGUF

# Launch
python server.py --listen --api
```

---

## ?? Computer Vision

### Object Detection with YOLO
```python
import torch
from PIL import Image

# Load YOLOv5
model = torch.hub.load('ultralytics/yolov5', 'yolov5s')
model = model.cuda()

# Load image
img = Image.open('image.jpg')

# Inference
results = model(img)

# Display results
results.show()
results.save('output/')
```

### Image Classification
```python
from transformers import AutoFeatureExtractor, AutoModelForImageClassification
from PIL import Image
import torch

# Load model
model_name = "microsoft/resnet-50"
extractor = AutoFeatureExtractor.from_pretrained(model_name)
model = AutoModelForImageClassification.from_pretrained(model_name).cuda()

# Load and process image
image = Image.open("cat.jpg")
inputs = extractor(images=image, return_tensors="pt").to("cuda")

# Classify
outputs = model(**inputs)
predictions = outputs.logits.softmax(-1)
predicted_class = predictions.argmax(-1).item()

print(f"Predicted class: {model.config.id2label[predicted_class]}")
```

---

## ??? Speech & Audio

### Whisper (Speech-to-Text)
```python
import torch
from transformers import WhisperProcessor, WhisperForConditionalGeneration

# Load model
processor = WhisperProcessor.from_pretrained("openai/whisper-base")
model = WhisperForConditionalGeneration.from_pretrained("openai/whisper-base")
model = model.cuda()

# Load audio
import librosa
audio, sr = librosa.load("audio.mp3", sr=16000)

# Transcribe
input_features = processor(audio, sampling_rate=sr, return_tensors="pt").input_features
input_features = input_features.cuda()

predicted_ids = model.generate(input_features)
transcription = processor.batch_decode(predicted_ids, skip_special_tokens=True)

print(transcription[0])
```

### Text-to-Speech
```python
from TTS.api import TTS
import torch

# Initialize TTS
tts = TTS(model_name="tts_models/en/ljspeech/tacotron2-DDC", gpu=True)

# Generate speech
text = "Hello, this is AMD ROCm text to speech!"
tts.tts_to_file(text=text, file_path="output.wav")
```

---

## ?? Machine Learning Training

### Custom Neural Network Training
```python
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset

# Define model
class SimpleNN(nn.Module):
    def __init__(self, input_size, hidden_size, output_size):
        super(SimpleNN, self).__init__()
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_size, output_size)
    
    def forward(self, x):
        x = self.fc1(x)
x = self.relu(x)
        x = self.fc2(x)
   return x

# Initialize
device = torch.device("cuda")
model = SimpleNN(784, 128, 10).to(device)
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)

# Training loop
def train_epoch(model, dataloader, criterion, optimizer):
    model.train()
    total_loss = 0
    
for inputs, labels in dataloader:
    inputs, labels = inputs.to(device), labels.to(device)
        
        optimizer.zero_grad()
    outputs = model(inputs)
        loss = criterion(outputs, labels)
     loss.backward()
        optimizer.step()
        
        total_loss += loss.item()
    
    return total_loss / len(dataloader)

# Example training
# train_loader = DataLoader(your_dataset, batch_size=32, shuffle=True)
# for epoch in range(10):
#     loss = train_epoch(model, train_loader, criterion, optimizer)
#     print(f"Epoch {epoch+1}, Loss: {loss:.4f}")
```

### PyTorch Lightning Training
```python
import torch
import pytorch_lightning as pl
from torch import nn
from torch.utils.data import DataLoader

class LitModel(pl.LightningModule):
    def __init__(self):
    super().__init__()
        self.layer = nn.Linear(28*28, 10)
    
def forward(self, x):
        return self.layer(x)
    
    def training_step(self, batch, batch_idx):
     x, y = batch
 x = x.view(x.size(0), -1)
 y_hat = self(x)
   loss = nn.functional.cross_entropy(y_hat, y)
        self.log('train_loss', loss)
        return loss
    
    def configure_optimizers(self):
 return torch.optim.Adam(self.parameters(), lr=0.001)

# Train
model = LitModel()
trainer = pl.Trainer(max_epochs=10, accelerator="gpu", devices=1)
# trainer.fit(model, train_dataloader)
```

---

## ?? Scientific Computing

### Molecular Dynamics Simulation
```python
import torch
import torch.nn as nn

class MolecularSystem:
    def __init__(self, n_particles, box_size):
        self.positions = torch.rand(n_particles, 3, device='cuda') * box_size
  self.velocities = torch.randn(n_particles, 3, device='cuda')
        self.forces = torch.zeros(n_particles, 3, device='cuda')
        self.box_size = box_size
    
    def compute_forces(self):
        # Lennard-Jones potential
        n = self.positions.shape[0]
        self.forces.zero_()
        
        for i in range(n):
  r = self.positions - self.positions[i]
       # Apply periodic boundary conditions
 r = r - self.box_size * torch.round(r / self.box_size)
            r_mag = torch.norm(r, dim=1)
            r_mag[i] = 1.0  # Avoid division by zero
     
       # Lennard-Jones force
     r6 = (1.0 / r_mag) ** 6
 force_mag = 24 * (2 * r6**2 - r6) / r_mag
            self.forces[i] = torch.sum(force_mag.unsqueeze(1) * r / r_mag.unsqueeze(1), dim=0)
    
    def integrate(self, dt):
        # Velocity Verlet integration
   self.positions += self.velocities * dt + 0.5 * self.forces * dt**2
        self.compute_forces()
 self.velocities += 0.5 * self.forces * dt
  
        # Apply periodic boundary conditions
        self.positions = self.positions % self.box_size

# Run simulation
system = MolecularSystem(n_particles=1000, box_size=10.0)
for step in range(1000):
    system.integrate(dt=0.001)
    if step % 100 == 0:
        print(f"Step {step}: Total energy = {torch.sum(system.velocities**2).item()}")
```

---

## ?? Reinforcement Learning

### Deep Q-Learning
```python
import torch
import torch.nn as nn
import torch.optim as optim
import numpy as np
from collections import deque
import random

class DQN(nn.Module):
    def __init__(self, state_size, action_size):
        super(DQN, self).__init__()
        self.fc1 = nn.Linear(state_size, 64)
      self.fc2 = nn.Linear(64, 64)
   self.fc3 = nn.Linear(64, action_size)
    
    def forward(self, x):
        x = torch.relu(self.fc1(x))
        x = torch.relu(self.fc2(x))
    return self.fc3(x)

class DQNAgent:
    def __init__(self, state_size, action_size):
        self.device = torch.device("cuda")
     self.model = DQN(state_size, action_size).to(self.device)
        self.target_model = DQN(state_size, action_size).to(self.device)
      self.optimizer = optim.Adam(self.model.parameters(), lr=0.001)
     self.memory = deque(maxlen=10000)
 self.gamma = 0.99
   self.epsilon = 1.0
    self.epsilon_decay = 0.995
   self.epsilon_min = 0.01
    
    def remember(self, state, action, reward, next_state, done):
        self.memory.append((state, action, reward, next_state, done))
    
  def act(self, state):
        if np.random.random() <= self.epsilon:
    return random.randrange(self.action_size)
        
        state = torch.FloatTensor(state).unsqueeze(0).to(self.device)
        with torch.no_grad():
     q_values = self.model(state)
        return torch.argmax(q_values).item()
    
    def replay(self, batch_size):
        if len(self.memory) < batch_size:
      return
      
        minibatch = random.sample(self.memory, batch_size)
        
        states = torch.FloatTensor([t[0] for t in minibatch]).to(self.device)
        actions = torch.LongTensor([t[1] for t in minibatch]).to(self.device)
        rewards = torch.FloatTensor([t[2] for t in minibatch]).to(self.device)
   next_states = torch.FloatTensor([t[3] for t in minibatch]).to(self.device)
dones = torch.FloatTensor([t[4] for t in minibatch]).to(self.device)
        
        current_q = self.model(states).gather(1, actions.unsqueeze(1))
        next_q = self.target_model(next_states).max(1)[0].detach()
        target_q = rewards + (1 - dones) * self.gamma * next_q
        
        loss = nn.functional.mse_loss(current_q.squeeze(), target_q)
 
        self.optimizer.zero_grad()
        loss.backward()
    self.optimizer.step()
        
 if self.epsilon > self.epsilon_min:
 self.epsilon *= self.epsilon_decay

# Usage with gym environment
# import gym
# env = gym.make('CartPole-v1')
# agent = DQNAgent(state_size=4, action_size=2)
# 
# for episode in range(1000):
#   state = env.reset()
#     for time in range(500):
#         action = agent.act(state)
#         next_state, reward, done, _ = env.step(action)
#         agent.remember(state, action, reward, next_state, done)
#         state = next_state
#         if done:
#    break
#     agent.replay(batch_size=32)
```

---

## ?? Tips for Optimal Performance

### Mixed Precision Training
```python
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()

for epoch in range(num_epochs):
    for inputs, labels in dataloader:
        inputs, labels = inputs.cuda(), labels.cuda()
        
        optimizer.zero_grad()
        
        with autocast():
    outputs = model(inputs)
            loss = criterion(outputs, labels)

   scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()
```

### Gradient Accumulation
```python
accumulation_steps = 4

for i, (inputs, labels) in enumerate(dataloader):
    inputs, labels = inputs.cuda(), labels.cuda()
    
    outputs = model(inputs)
    loss = criterion(outputs, labels)
    loss = loss / accumulation_steps
    loss.backward()
    
    if (i + 1) % accumulation_steps == 0:
        optimizer.step()
        optimizer.zero_grad()
```

### Memory Management
```python
import torch

# Clear cache
torch.cuda.empty_cache()

# Check memory usage
print(f"Allocated: {torch.cuda.memory_allocated(0) / 1024**2:.2f} MB")
print(f"Cached: {torch.cuda.memory_reserved(0) / 1024**2:.2f} MB")

# Profile memory
with torch.cuda.profiler.profile():
    # Your code here
    pass
```

---

## ?? Additional Resources

- [PyTorch ROCm Documentation](https://ROCm.docs.amd.com/projects/radeon/en/latest/docs/install/wsl/install-pytorch.html)
- [Hugging Face with ROCm](https://huggingface.co/docs/transformers/main/en/perf_train_gpu_one)
- [AMD ROCm Blog](https://ROCm.blogs.amd.com/)
- [ROCm Examples GitHub](https://github.com/ROCmSoftwarePlatform)

---

**Have you built something cool with ROCm? Share it with the community!**
