# Phonk UI integration preview

Run only in +1 Phonk Evolution (Place ID 104809044319701).
This is the supplied game script connected to a pinned preview UI, with a separate preview configuration path. Re-execution destroys the previous Phonk app where available.

All 24 identified original controls map to their original IDs and Changed callbacks. Automation resets to the supplied defaults (OFF) each build. Performance is labelled Misc; original Settings is labelled Game Tuning, preserving its config keys. Shared UI appearance/profiles remain separate.

The source from GuiService initialization through the complete manifest is byte-for-byte unchanged. No game mechanic has been refactored. This retains the original built-in behavior as well as its automation switches. Webhook, auto reconnect and other absent shared game features are not implemented in this test.

Mock verification: all original identified controls exist, mounting does not call Changed, AutoClick change calls its callback once, restart returns it OFF, and runtime cleanup runs. Existing preview tests pass. Actual game automation and mobile rendering have NOT been tested here.

Source SHA256: 9e689c36ab240c48f0942a04428b38768039bf1c098b7a851c5f9c096b180c4c
