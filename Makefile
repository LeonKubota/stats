build:
	@odin build stats
	@echo "Ignore the stack overflow warnings!!"

proper:
	@odin build stats -o:size -ignore-warnings

test:
	@odin test stats -keep-executable

.PHONY: clean
clean:
	rm stats.bin
