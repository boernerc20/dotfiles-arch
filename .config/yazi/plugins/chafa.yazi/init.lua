local M = {}

function M:peek(job)
	local w = job.area.w
	local h = job.area.h
	if w == 0 or h == 0 then return end

	local output, err = Command("chafa")
		:arg({
			"--format", "symbols",
			"--colors", "full",
			"--color-extractor", "median",
			"--animate", "false",
			"--size", w .. "x" .. h,
			tostring(job.file.url),
		})
		:stderr(Command.NULL)
		:output()

	if not output then
		ya.err("chafa previewer failed: " .. tostring(err))
		return
	end

	ya.preview_widget(
		{ area = job.area, file = job.file, mime = job.mime, skip = job.skip },
		ui.Text.parse(output.stdout):area(job.area)
	)
end

function M:seek(job)
end

return M
