.PHONY: restore-plugins clean clean-dry-run

restore-plugins:
	@echo "Restoring plugins..."
	bash ./scripts/shell/restore-plugins.sh
	@echo "Plugins restored successfully!"
	