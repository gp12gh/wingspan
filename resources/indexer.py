# Script to mark index items for BC newsletter.
from Npp import editor
start = editor.getSelectionStart()
end = editor.getSelectionEnd()
if start == end: # No selection, so insert J markers
  editor.beginUndoAction()
  editor.addText('J----J')
  current_pos = editor.getCurrentPos()
  editor.setCurrentPos(current_pos - 3)
  editor.setSelection(current_pos - 3, current_pos - 3)
  editor.endUndoAction()
else: # there is a selection so surround it with I markers
  editor.beginUndoAction()
  editor.setSelectionStart(start)
  editor.setSelectionEnd(end)
  selected_text = editor.getSelText()
  editor.replaceSel('I--' + selected_text + '--I')
  editor.endUndoAction()