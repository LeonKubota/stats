build:
	@odin build stats
	@echo "compiled successfully!"

proper:
	@odin build stats -o:size

.PHONY: clean
clean:
	rm stats.bin
