FROM rocm/pytorch:latest

# Install vLLM and dependencies
RUN pip install --no-cache-dir vllm

# Expose port for API
EXPOSE 8000

# Entrypoint to run vLLM server
ENTRYPOINT ["python", "-m", "vllm.entrypoints.openai.api_server"]
CMD ["--host", "0.0.0.0", "--port", "8000"]
