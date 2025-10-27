# ?? Environment Management Workflow

## Initial Setup on Primary Machine

1. **Create Environment**
```bash
# Create from environment.yml
conda env create -f environment.yml

# Activate environment
conda activate ROCm_installer_env
```

2. **Verify Installation**
```bash
# List installed packages
conda list

# Check environment location
conda env list
```

## Working on Multiple Machines

### Setting Up on New Machine
1. **Clone Repository**
```bash
git clone https://github.com/OCNGill/ROCm_Installer_Win11.git
cd ROCm_Win11_installer
```

2. **Create Environment**
```bash
conda env create -f environment.yml
conda activate ROCm_installer_env
```

3. **Configure VS Code**
- Press `Ctrl+Shift+P`
- Type "Python: Select Interpreter"
- Choose `ROCm_installer_env` from the list

### Making Environment Changes

1. **Adding New Packages**
```bash
# Install new package
conda install package_name
# or
pip install package_name

# Update environment.yml
conda env export > environment.yml
```

2. **Commit and Push Changes**
```bash
git add environment.yml
git commit -m "Update environment dependencies"
git push
```

### Syncing Changes on Other Machines

1. **Pull Latest Changes**
```bash
git pull
```

2. **Update Environment**
```bash
conda env update -f environment.yml
```

## Maintenance Tasks

### Cleaning Up
```bash
# Remove unused packages
conda clean --all

# Remove environment if needed
conda deactivate
conda env remove -n ROCm_installer_env
```

### Troubleshooting

1. **Environment Issues**
- Check if environment exists: `conda env list`
- Verify active environment: `conda info --envs`
- List packages: `conda list`

2. **Git Sync Issues**
```bash
# If push rejected
git pull
git push

# If merge conflicts in environment.yml
git checkout --ours environment.yml
git add environment.yml
git commit -m "Resolve environment.yml conflict"
```

## Best Practices

1. **Environment Management**
- Keep `environment.yml` up to date
- Use consistent Python version across machines
- Document required system dependencies

2. **Version Control**
- Always pull before making environment changes
- Push environment changes immediately
- Include clear commit messages

3. **IDE Integration**
- Always use the correct interpreter in VS Code
- Verify environment activation in terminal
- Keep VS Code Python extension updated