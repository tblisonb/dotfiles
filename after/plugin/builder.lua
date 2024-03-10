require("builder").setup({
    type = "float",
    commands = {
        --c = "cd $dir\\% && C:\\working\\systems\\programFiles\\python\\python.3.8.10\\python.exe $dir\\bin\\clean.py && C:\\working\\systems\\programFiles\\python\\python.3.8.10\\python.exe $dir\\bin\\build.py",
        --c = "cd $dir\\% && C:\\working\\systems\\programFiles\\python\\python.3.8.10\\python.exe $dir\\bin\\build.py",
        --cpp = "build.py",
    },
})
