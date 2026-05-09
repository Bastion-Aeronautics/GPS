bool = false

function onTick()
    async.httpGet(1575, '/readClick') --calls the "readclick" function in the py webserver
    output.setBool(1, bool)
end

function httpReply(port, request_body, response_body)
    if request_body == '/readClick' then --returns what we asked for
        if response_body == "True" then  --python bools are capitalized
            bool = true
        elseif response_body == "False" then
            bool = false
        else --just in case
            bool = false
        end
    else
        --request body doesnt work?
    end
end
