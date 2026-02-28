function port -d "Check what's running on a port"
    lsof -i ":$argv[1]"
end
