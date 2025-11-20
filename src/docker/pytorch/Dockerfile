FROM rocm/pytorch:latest

# Install JupyterLab and other dev tools
RUN pip install --no-cache-dir jupyterlab matplotlib pandas scikit-learn

# Expose port for Jupyter
EXPOSE 8888

# Set working directory
WORKDIR /workspace

# Start JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
