.PHONY: restore-plugins
restore-plugins:
	@echo "Restoring plugins..."
	sh ./scripts/shell/restore-plugins.sh
	@echo "Plugins restored successfully!"
	