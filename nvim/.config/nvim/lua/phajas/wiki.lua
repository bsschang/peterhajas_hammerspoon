History = require("phajas.wiki_history")
Info = require("phajas.wiki_info")
Paths = require("phajas.wiki_paths")

local function DEBUG(thing)
    vim.api.nvim_echo({ { vim.inspect( thing) } }, true, {})
end

local function WikiFileWithTitle(title)
    local files = vim.fn.globpath(Paths.WikiPath(), '**/' .. title .. ".md", 1, 1)

    if not files or #files == 0 then
        return nil
    end

    return files[1]
end

local function WikiNavigateToFile(winno, frombufno, title)
    DEBUG(title)
    local path = WikiFileWithTitle(title)
    local fromPath = vim.api.nvim_buf_get_name(frombufno)
    if path == nil then
        local directory = vim.fn.fnamemodify(fromPath, ":h")
        local newPath = directory .. "/" .. title .. ".md"
        local file = io.open(newPath, 'w')
        if file then
            path = newPath
            file:close()
        else
            print('Failed to create the file:', newPath)
            return
        end
    end

    History.PushHistory(winno, fromPath)

    vim.api.nvim_command("edit " .. path)
end

local function WikiBufferOpenFileAtCursor(winno, bufno)
    local row, column = unpack(vim.api.nvim_win_get_cursor(winno))
    local line = vim.api.nvim_buf_get_lines(bufno, row-1, row, false)[1]
    local startIndex = nil
    local endIndex = nil
    local title = nil
    startIndex, endIndex = 1, 1

    -- Find where square brackets are, if anywhere
    while startIndex and endIndex do
        startIndex, endIndex = string.find(line, "%[%[", endIndex)
        if startIndex and endIndex then
            local startBrackets, endBrackets = string.find(line, "%]%]", endIndex)
            if startBrackets and endBrackets then
                title = string.sub(line, startIndex, endBrackets)
                endIndex = endBrackets + 1
                break
            end
        end
    end

    if startIndex ~= nil and endIndex ~= nil and
       startIndex < column+2 and endIndex > column-2 and
       title ~= nil then
        title = string.gsub(title, "%[", "")
        title = string.gsub(title, "%]", "")
        WikiNavigateToFile(winno, bufno, title)
    else
        print("Not yet implemented") -- plh-evil: fix me, find selected text
    end
end

local function WikiGoBack(winno)
    local path = History.PopHistory(winno)
    if path ~= nil then
        vim.api.nvim_command("edit " .. path)
    end
end

local function WikiBufferEnter(info)
    local bufno = info.buf

    vim.api.nvim_buf_set_keymap(bufno, 'n', '<CR>', '', {
        callback = function()
            local winno = vim.api.nvim_get_current_win()
            WikiBufferOpenFileAtCursor(winno, bufno)
        end
    })
    vim.api.nvim_buf_set_keymap(bufno, 'v', '<CR>', '', {
        callback = function()
            local winno = vim.api.nvim_get_current_win()
            WikiBufferOpenFileAtCursor(winno, bufno)
        end
    })
    vim.api.nvim_buf_set_keymap(bufno, 'n', '<BS>', '', {
        callback = function()
            local winno = vim.api.nvim_get_current_win()
            WikiGoBack(winno)
        end
    })
    vim.api.nvim_buf_set_keymap(bufno, 'n', '^', '', {
        callback = function()
            local winno = vim.api.nvim_get_current_win()
            Info.ShowInfo(bufno, winno)
        end
    })
end

vim.api.nvim_create_autocmd({"BufEnter"}, {
    group = vim.api.nvim_create_augroup("phajas-wiki", { clear = true }),
    pattern = Paths.WikiFilePattern(),
    callback = function(info)
        local extension = string.match(info.file, "%.([^%.]+)$")
        if extension and string.lower(extension) == "md" then
            WikiBufferEnter(info)
        end
    end,
})

