/*HeaderStart*******************************************************
Tool Name:	Ollie Rig Renamer
Created By:	Josh Aitken
Company:	Keyframe Digital
E-Mail:		******
Start Date:	2016-11-30
Last Updated:	2016-12-16

Disclaimer:
This script has been tested to the best of the author's ability. Use at your own risk.
Any damage caused by this script is not the responsibility of the author.

Purpose:
	Allows rig renaming to give base rigs for variants

History:
	

To Do:
	

Bugs:
	

Notes:
	

Tested in:
	Max 2016 SP4

Tests:
	createDialog KF_rigRenamerR

*********************************************************HeaderEnd*/

try(destroyDialog KF_rigRenamer.KF_rigRenamerR)catch()
KF_rigRenamer = undefined
KF_rigRenamerR=undefined


struct KF_rigRenamer
(
	KF_rigRenamerR=undefined,
	
	CharIndex = 1,
	
	fn LoadChars =
	(
		CharLayer = LayerManager.getLayerFromName "CHAR"
		
		CharCount = CharLayer.getnumchildren()
		CharAr = #()
		for x = 1 to CharCount do append CharAr ((CharLayer.getChild x).name)
		
		if CharIndex > CharCount then CharIndex = CharCount else ()
		
		KF_rigRenamerR.OldCharName_et.text = CharAr[CharIndex]
		
		if CharIndex < CharCount then CharIndex += 1 else (CharIndex = 1)
	),
	
	fn UI=
	(
		rollout KF_rigRenamerR "Rig Renamer" width:250
		(			
			edittext OldCharName_et "Current Name:" align:#center width:210
			edittext newCharName_et "New Name:     " align:#center width:210
			Button NextChar_bt "Next Char" width:110 across:2
			button renameRig_bt "Rename Rig" width:110
			
			on newCharName_et changed txt do
			(
				--if txt.count > 3 then newCharName_et.text = substring txt 1 3
			)
			
			on renameRig_bt pressed do
			(
				OldName = OldCharName_et.text
				newChar = newCharName_et.text
				
				for x in objects do 
				(
					if (findstring x.name OldName) != undefined then
					(
						x.name = (substituteString x.name OldName NewChar)
					)else print x.name
				)
					
				CharacterLayer = LayerManager.getLayerFromName OldCharName_et.text
					
				SubLayerCount = CharacterLayer.getnumchildren()
				
				CharAr = #()
				
				for x = 1 to SubLayerCount do 
				(
					SubLayer = CharacterLayer.getChild x
					newLayerName = (substituteString (Sublayer.name) OldName NewChar)
					SubLayer.setname newLayerName 
					
					SubLayer.nodes &theNodes
					
					for y in theNodes do
					(
						ProperLayer = (LayerManager.getLayerFromName (substituteString (Sublayer.name) OldName NewChar))
						try(ProperLayer.addNode y) catch()
					)
				)
				
				for x in SubLayerCount to 1 by -1 do 
				(
					SubLayer = CharacterLayer.getChild x
					layermanager.DeleteLayerByName SubLayer.name
				)
				
				CharacterLayer.setname newChar
				
				matcount = 0
				macros.run "Medit Tools" "clear_medit_slots"
				for m in sceneMaterials do 
				(
					if (findstring m.name OldName) != undefined then
					(
						m.name = (substituteString m.name OldName NewChar)
					)else 
					(
						matcount += 1
						try(setmeditmaterial matcount m) catch()
					)
				)
				
				if (CharacterLayer.getnumchildren()) == 0 do layermanager.DeleteLayerByName CharacterLayer.name
				
				KF_rigRenamer.LoadChars()
			)
			
			on NextChar_bt pressed do
			(
				KF_rigRenamer.LoadChars()
			)
			
			on KF_rigRenamerR open do
			(
				KF_rigRenamer.LoadChars()
			)
			
			on KF_rigRenamerR close do
			(
				KF_rigRenamer.KF_rigRenamerR=undefined
			)
		)
	)
)

(layermanager.getlayer 0).current = true

KF_rigRenamer=KF_rigRenamer()
KF_rigRenamerR=KF_rigRenamer.UI()
createDialog KF_rigRenamerR
