.PHONY: restore-plugins clean clean-dry-run

restore-plugins:
	@echo "Restoring plugins..."
	sh ./scripts/shell/restore-plugins.sh
	@echo "Plugins restored successfully!"

clean:
	sh ./scripts/shell/cleanup.sh

clean-dry-run:
	sh ./scripts/shell/cleanup.sh --dry-run
	