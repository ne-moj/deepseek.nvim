-- NEW --
local M = {}

local function get_module_path(module_name)
	local info = debug.getinfo(2, "S")
	if info and info.source:sub(1, 1) == "@" then
		return info.source:sub(2):gsub("[/\\][^/\\]+%.lua$", "")
	end

	vim.notify(
		"❗ Не удалось определить путь до модуля: " .. (module_name or "unknown"),
		vim.log.levels.WARN
	)
	return nil
end

local function load_setup(loaded, opts)
	local mt = getmetatable(loaded)
	-- 1️⃣ Если это класс (у него метод setup в прототипе/метатаблице)
	if mt and type(mt.__index) == "table" then
		if type(mt.__index.setup) == "function" then
			loaded:setup(opts) -- Вызов через двоеточие для сохранения self
		end
	elseif mt then
		if type(mt.setup) == "function" then -- 3️⃣ Если это экземпляр класса, метод лежит в метатаблице
			mt.setup(loaded, opts)
		end
	elseif type(loaded) == "table" and type(loaded.setup) == "function" then -- 2️⃣ Если это таблица-модуль с методом setup
		loaded.setup(opts)
	end
end

local function load_submodules(path, prefix, opts, ignore_init)
	local handle = vim.uv.fs_scandir(path)
	if not handle then
		return
	end

	local has_init = false
	local entries = {}

	while true do
		local name, t = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end

		if name == "init.lua" then
			has_init = not ignore_init
		else
			table.insert(entries, { name = name, type = t })
		end
	end

	-- Если есть init.lua, доверяем ему самому решать, что делать
	if has_init then
		local module_name = prefix:sub(1, -2)
		local ok, loaded = pcall(require, module_name)
		if ok then
			load_setup(loaded, opts)
		end
		return
	end
	--
	-- 📌 Если указан порядок, сортируем по нему
	table.sort(entries, function(a, b)
		local a_name = a.name:gsub("%.lua$", "")
		local b_name = b.name:gsub("%.lua$", "")
		local a_index = opts and opts[a_name] and opts[a_name].order or 50
		local b_index = opts and opts[b_name] and opts[b_name].order or 50
		return a_index < b_index
	end)

	-- Если нет init.lua — загружаем все файлы
	for _, entry in ipairs(entries) do
		local name, t = entry.name, entry.type
		local short_name = name:gsub("%.lua$", "")
		local local_opts = opts and opts[short_name] or {}
		local_opts.disable = local_opts.disable or false

		if t == "file" and name:match("%.lua$") and name ~= "init.lua" then
			-- 📌 Фильтрация загрузки через opts
			if not local_opts.disable then
				local mod_name = prefix .. short_name
				local ok, loaded = pcall(require, mod_name)
				if ok then
					M[short_name] = loaded
					-- 📌 Применяем сразу конфигурацию, если она есть
					load_setup(loaded, local_opts)
				else
					vim.notify("Не удалось загрузить модуль: " .. mod_name, vim.log.levels.WARN)
				end
			end
		elseif t == "directory" then
			-- 📌 Передаём только конкретные опции этого модуля, если есть
			load_submodules(path .. "/" .. name, prefix .. name .. ".", local_opts, false)
		end
	end
end

function M.setup(opts)
	opts = opts or {}

	-- 📌 подгружаем настройки в первую очередь
	local cfg = require("deepseek.config")
	cfg.setup(opts)

	-- 📌 Задаём путь на лету, можно использовать package.searchpath для динамики
	local base_path = get_module_path("deepseek")
	local base_module = "deepseek."

	-- 📌 Загружаем модули только сейчас, с параметрами!
	load_submodules(base_path, base_module, cfg.get_config(), true)

	-- 📌 Например, применяем сразу конфигурацию, если она есть
end

return M
