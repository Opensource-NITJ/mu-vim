return {
	"CRAG666/code_runner.nvim",
	config = function()
		local active_job_id = nil
		local input_buf = nil
		local output_buf = nil
		local input_win = nil
		local output_win = nil
		local runner_mode = "buffer" -- default mode

		local function clean_old_buffers()
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_valid(buf) then
					local name = vim.api.nvim_buf_get_name(buf)
					if name:match("%[Input%]$") or name:match("%[Output%]$") then
						pcall(vim.api.nvim_buf_delete, buf, { force = true })
					end
				end
			end
		end

		local function run_with_buffers(cmd)
			-- Clean up previous run's buffers if any are still valid/open
			clean_old_buffers()

			-- Save the current source file buffer if modified
			vim.cmd("silent! write")

			-- Create input buffer (scratch buffer)
			input_buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_name(input_buf, "[Input]")
			vim.bo[input_buf].buftype = "nofile"
			vim.bo[input_buf].bufhidden = "wipe"
			vim.bo[input_buf].swapfile = false

			-- Create output buffer (scratch buffer)
			output_buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_name(output_buf, "[Output]")
			vim.bo[output_buf].buftype = "nofile"
			vim.bo[output_buf].bufhidden = "wipe"
			vim.bo[output_buf].swapfile = false
			vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, {
				"Ready. Paste input in [Input] buffer on the left,",
				"then press <CR> (Enter) in Normal Mode to run.",
				"",
				"Press 'q' in Normal Mode on either buffer to close both.",
			})

			-- Split layout: open a horizontal split at the bottom for input
			vim.cmd("botright split")
			input_win = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(input_win, input_buf)
			vim.cmd("resize 12") -- Set input pane height

			-- Split the bottom pane vertically for the output
			vim.cmd("vertical rightbelow split")
			output_win = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(output_win, output_buf)

			-- Keep focus on the input window so user can paste input immediately
			vim.api.nvim_set_current_win(input_win)

			-- Auto-close linking: closing either buffer/window will close the other side together
			local is_closing = false
			local function close_both()
				if is_closing then
					return
				end
				is_closing = true
				if active_job_id then
					pcall(vim.fn.jobstop, active_job_id)
					active_job_id = nil
				end
				pcall(function()
					if input_win and vim.api.nvim_win_is_valid(input_win) then
						vim.api.nvim_win_close(input_win, true)
					end
				end)
				pcall(function()
					if output_win and vim.api.nvim_win_is_valid(output_win) then
						vim.api.nvim_win_close(output_win, true)
					end
				end)
				pcall(function()
					if input_buf and vim.api.nvim_buf_is_valid(input_buf) then
						vim.api.nvim_buf_delete(input_buf, { force = true })
					end
				end)
				pcall(function()
					if output_buf and vim.api.nvim_buf_is_valid(output_buf) then
						vim.api.nvim_buf_delete(output_buf, { force = true })
					end
				end)
				is_closing = false
			end

			vim.api.nvim_create_autocmd("BufWipeout", {
				buffer = input_buf,
				callback = close_both,
			})
			vim.api.nvim_create_autocmd("BufWipeout", {
				buffer = output_buf,
				callback = close_both,
			})

			-- Set up local shortcut 'q' to close both windows instantly
			vim.keymap.set("n", "q", close_both, { buffer = input_buf, silent = true, desc = "Close runner buffers" })
			vim.keymap.set("n", "q", close_both, { buffer = output_buf, silent = true, desc = "Close runner buffers" })

			-- Map <CR> (Enter) in normal mode in the input buffer to trigger code execution
			vim.keymap.set("n", "<CR>", function()
				if active_job_id then
					pcall(vim.fn.jobstop, active_job_id)
					active_job_id = nil
				end

				-- Gather input buffer contents
				local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
				local input_text = table.concat(lines, "\n")
				if #lines > 0 then
					input_text = input_text .. "\n"
				end

				-- Clear output and show "[Running...]"
				vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, { "[Running...]" })
				local initialized = false

				-- Streaming function to append output in real-time
				local function append_output(_, data)
					if not data or #data == 0 then
						return
					end
					if not vim.api.nvim_buf_is_valid(output_buf) then
						return
					end

					local current_lines = vim.api.nvim_buf_get_lines(output_buf, 0, -1, false)
					if not initialized then
						current_lines = { "" }
						initialized = true
					end

					-- Merge the incoming chunk correctly
					current_lines[#current_lines] = current_lines[#current_lines] .. data[1]
					for i = 2, #data do
						table.insert(current_lines, data[i])
					end

					vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, current_lines)

					-- Auto-scroll output window to the end
					if output_win and vim.api.nvim_win_is_valid(output_win) then
						local line_count = vim.api.nvim_buf_line_count(output_buf)
						vim.api.nvim_win_set_cursor(output_win, { line_count, 0 })
					end
				end

				-- Redirect stderr to stdout to interleave outputs correctly
				local shell_cmd = string.format("( %s ) 2>&1", cmd)

				active_job_id = vim.fn.jobstart(shell_cmd, {
					on_stdout = append_output,
					on_stderr = append_output,
					on_exit = function(_, exit_code)
						active_job_id = nil
						append_output(nil, { "", string.format("[Process exited with code %d]", exit_code), "" })
					end,
				})

				if active_job_id > 0 then
					-- Feed the input text into stdin
					vim.fn.chansend(active_job_id, input_text)
					vim.fn.chanclose(active_job_id, "stdin")
				else
					vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, { "Error: Failed to launch command." })
				end
			end, { buffer = input_buf, silent = true, desc = "Execute runner with input" })
		end

		local function run_in_wezterm(cmd)
			if vim.fn.has("win32") == 1 then
				-- Write the command to a temp .ps1 file to avoid shell quoting issues
				local tmpdir = os.getenv("TEMP") or os.getenv("TMP") or (os.getenv("USERPROFILE") .. "\\AppData\\Local\\Temp")
				local tmpfile = tmpdir .. "\\mu_vim_runner.ps1"
				local f = io.open(tmpfile, "w")
				if f then
					f:write(cmd .. "\nWrite-Host ''\nRead-Host 'Press Enter to exit'")
					f:close()
				end
				vim.fn.jobstart('wezterm cli split-pane --bottom --percent 30 -- pwsh -NoLogo -File "' .. tmpfile .. '"')
			else
				local wez_cmd = string.format(
					"wezterm cli split-pane --bottom --percent 30 -- sh -c %s",
					vim.fn.shellescape(cmd .. "; echo; echo 'Press Enter to exit...'; read REPLY")
				)
				vim.fn.jobstart(wez_cmd)
			end
		end

		local function run_code(cmd)
			if runner_mode == "terminal" then
				vim.cmd("silent! write")
				run_in_wezterm(cmd)
			else
				run_with_buffers(cmd)
			end
		end

		local function toggle_mode()
			if runner_mode == "buffer" then
				runner_mode = "terminal"
				vim.notify("Code Runner Mode: Terminal (Interactive)", vim.log.levels.INFO)
			else
				runner_mode = "buffer"
				vim.notify("Code Runner Mode: Buffer (I/O splits)", vim.log.levels.INFO)
			end
		end

		_G.toggle_code_runner_mode = toggle_mode

		require("code_runner").setup({
			filetype = {
				c = function()
					local dir = vim.fn.expand("%:p:h")
					local fileName = vim.fn.expand("%:t")
					local fileNameWithoutExt = vim.fn.expand("%:t:r")
					local cmd
					if vim.fn.has("win32") == 1 then
						-- On Windows: output to %TEMP% with .exe extension; use & to invoke the binary
						cmd = string.format(
							'cd %s && gcc %s -o "$env:TEMP\\%s.exe" && & "$env:TEMP\\%s.exe"',
							vim.fn.shellescape(dir),
							vim.fn.shellescape(fileName),
							fileNameWithoutExt,
							fileNameWithoutExt
						)
					else
						cmd = string.format(
							"cd %s && gcc %s -o /tmp/%s && /tmp/%s",
							vim.fn.shellescape(dir),
							vim.fn.shellescape(fileName),
							vim.fn.shellescape(fileNameWithoutExt),
							vim.fn.shellescape(fileNameWithoutExt)
						)
					end
					run_code(cmd)
				end,
				cpp = function()
					local dir = vim.fn.expand("%:p:h")
					local fileName = vim.fn.expand("%:t")
					local fileNameWithoutExt = vim.fn.expand("%:t:r")
					local cmd
					if vim.fn.has("win32") == 1 then
						cmd = string.format(
							'cd %s && g++ %s -o "$env:TEMP\\%s.exe" && & "$env:TEMP\\%s.exe"',
							vim.fn.shellescape(dir),
							vim.fn.shellescape(fileName),
							fileNameWithoutExt,
							fileNameWithoutExt
						)
					else
						cmd = string.format(
							"cd %s && g++ %s -o /tmp/%s && /tmp/%s",
							vim.fn.shellescape(dir),
							vim.fn.shellescape(fileName),
							vim.fn.shellescape(fileNameWithoutExt),
							vim.fn.shellescape(fileNameWithoutExt)
						)
					end
					run_code(cmd)
				end,
				py = function()
					local dir = vim.fn.expand("%:p:h")
					local fileName = vim.fn.expand("%:t")
					local python = vim.fn.has("win32") == 1 and "python" or "python3"
					local cmd = string.format(
						"cd %s && %s %s",
						vim.fn.shellescape(dir),
						python,
						vim.fn.shellescape(fileName)
					)
					run_code(cmd)
				end,
			},
		})
	end,
}
