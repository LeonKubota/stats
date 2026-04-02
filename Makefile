build:
	@odin build stats

proper:
	@odin build stats -o:size -ignore-warnings

.PHONY: clean
clean:
	rm stats.bin
