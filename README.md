task.spawn(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Kauativor/Flow-flash/refs/heads/main/flashflow.lua"))()
end)

task.wait(1)

task.spawn(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Kauativor/esp-brainrots/refs/heads/main/espbest.lua"))()
end)
