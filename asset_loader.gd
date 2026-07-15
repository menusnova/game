extends Node
# ════════════════════════════════════════════════════════════
#  CHEMIA — AssetLoader (autoload)
#  Loads textures even when the image has no Godot .import file yet
#  (freshly uploaded PNG/JPG). Falls back to reading the raw file
#  bytes and decoding them at runtime, so art shows without needing
#  to open the editor first. Results are cached.
# ════════════════════════════════════════════════════════════

var _cache: Dictionary = {}   # path -> Texture2D

## Returns a Texture2D for `path`, or null if it can't be loaded at all.
func tex(path: String) -> Texture2D:
	if path == "":
		return null
	if _cache.has(path):
		return _cache[path]

	# Fast path: properly imported resource
	if ResourceLoader.exists(path):
		var t := load(path) as Texture2D
		if t:
			_cache[path] = t
			return t

	# Fallback: decode the raw file (works with no .import file present)
	if FileAccess.file_exists(path):
		var buf := FileAccess.get_file_as_bytes(path)
		if buf.size() > 0:
			var img := Image.new()
			var ext := path.get_extension().to_lower()
			var err := ERR_FILE_UNRECOGNIZED
			match ext:
				"png":         err = img.load_png_from_buffer(buf)
				"jpg", "jpeg": err = img.load_jpg_from_buffer(buf)
				"webp":        err = img.load_webp_from_buffer(buf)
			if err == OK:
				var it := ImageTexture.create_from_image(img)
				_cache[path] = it
				return it

	return null

## True if a texture can be produced for `path` (imported OR raw file present).
func has(path: String) -> bool:
	if path == "": return false
	if _cache.has(path): return true
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)
