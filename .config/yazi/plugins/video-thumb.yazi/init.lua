local M = {}

function M:peek(job)
	local w = job.area.w
	local h = job.area.h
	if w == 0 or h == 0 then return end

	local tmp = "/tmp/yazi-vthumb-" .. tostring(math.random(1000000)) .. ".jpg"

	Command("ffmpegthumbnailer")
		:arg({ "-i", tostring(job.file.url), "-o", tmp, "-s", "512", "-q", "5" })
		:stderr(Command.NULL)
		:output()

	local output, err = Command("chafa")
		:arg({
			"--format", "symbols",
			"--colors", "full",
			"--animate", "false",
			"--size", w .. "x" .. h,
			tmp,
		})
		:stderr(Command.NULL)
		:output()

	Command("rm"):arg({ "-f", tmp }):stderr(Command.NULL):output()

	if not output then
		ya.err("video-thumb previewer failed: " .. tostring(err))
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
