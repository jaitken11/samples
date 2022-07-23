/*HeaderStart*******************************************************
Tool Name:	Ollie Tools
Created By:	Josh Aitken
Company:	Keyframe Digital
E-Mail:		******
Start Date:	2016-8-18
Last Updated:	2018-7-26

Disclaimer:
This script has been tested to the best of the author's ability. Use at your own risk.
Any damage caused by this script is not the responsibility of the author.

Purpose:
	Main tool interface for Ollie production

History:
	

To Do:
	

Bugs:
	

Notes:
	

Tested in:
	Max 2016 SP4

Tests:
	Ollie_Tools.run 825 415

*********************************************************HeaderEnd*/

try
(
	destroyDialog Ollie_Tools._Ollie_ToolsR
	destroydialog Ollie_Tools._OllieFixR
	callbacks.RemoveScripts #filePostSave id:#Ollie_Tools_postsave
	callbacks.RemoveScripts #filePreOpenProcess id:#Ollie_Tools_preload
	callbacks.RemoveScripts #filePostOpenProcess id:#Ollie_Tools_postload
)
catch()

struct Ollie_Tools
(
	/*Declare Variables*/
	_Ollie_ToolsR=undefined,
	Filename=undefined,
	PBFile=undefined,
	ApprovalDir=undefined,
	EXRApprovalDir=undefined,
	PoseSaverCNTs=#(),
	
	_OllieFixR=undefined,
	_FixTypeList=#("Animation","Texturing","Modelling"), --"FX",
	_FixList=#(),
	_FixListUI=#(),
	_fixoutPath=undefined,
	
	/*CommentStart*******************************************************
	Callback Definitions
	*********************************************************CommentEnd*/

	cbackloadcheck=0,
	dlpos=[0,0],

	Ollie_Tools_postsave_message="
if Ollie_Tools._Ollie_ToolsR.open==true do with undo off animate off
(
	Ollie_Tools.filecheck()
)
",

	Ollie_Tools_preload_message="
Ollie_Tools.cbackloadcheck=1
undo off 
(
	try
	(
		Ollie_Tools.dlpos=GetDialogPos Ollie_Tools._Ollie_ToolsR
		destroyDialog Ollie_Tools._Ollie_ToolsR
	)catch()
)
",

	Ollie_Tools_postload_message="
Ollie_Tools.run Ollie_Tools.dlpos[1] Ollie_Tools.dlpos[2]
Ollie_Tools.cbackloadcheck=0
",
	
	
	/*CommentStart*******************************************************
	Functions
	*********************************************************CommentEnd*/

	/*FnStart*******************************************************
	Function: Get chains for Rigs
	*********************************************************FnEnd*/
        fn collectMyChildren obj includeParent:true =
	(
		myChildren = #(obj)
		i = 0
		while i < myChildren.count do
		(
			i += 1
			join myChildren myChildren[i].children
		)

		if not includeParent then deleteitem myChildren 1

		myChildren
	),

	/*FnStart*******************************************************
	Function: Attempts to rekey poses based on new pose data
	*********************************************************FnEnd*/
	fn ReKeyPoses CNT = 
	(	
		clearselection()
		if CNT != undefined then Select CNT
		if selection.count == 1 then
		(
			max modify mode
			PoseMod = undefined
			for m in selection[1].modifiers where classof m == posesaver do (PoseMod = m)
			if PoseMod != undefined then
			(
				if PoseMod.poseSaverR.open then
				(	
					if PoseMod.MasterMode then
					(
						MasterKeys = #()
						PoseKeys = #()

						for x in (PoseMod.MasterState.keys) do (append MasterKeys ((x.time as integer)/ticksperframe))
						for x in (PoseMod.PoseState.keys) do (append PoseKeys ((x.time as integer)/ticksperframe))

						AllKeys = MasterKeys + PoseKeys
						AllKeys = makeUniqueArray AllKeys
						AllKeys = sort AllKeys

						with redraw off
						(
							undo off
							(
								FailedKeys = #()
								for t in AllKeys do
								(
									if (t >= ((animationrange.start as integer)/ticksperframe)) and (t <= ((animationrange.end as integer)/ticksperframe)) then
									(
										sliderTime = t
										try
										(
											PoseMod.setPoseValues PoseMod.poseSaverR.poseListDn.nodes.item[PoseMod.MasterState].nodes.item[PoseMod.PoseState]
										)
										catch
										(
											Append FailedKeys t
										)
									)else()
								)
							)
						)
						
						if FailedKeys[1] != undefined then
						(
							messageBox ("Frame(s) "+(FailedKeys as string)+" could not be updated.")
						)else()
					)else
					(
						MasterKeys = #()
						PoseKeys = #()
						
						for x in (PoseMod.RawSubMaster.keys) do (append MasterKeys ((x.time as integer)/ticksperframe))
						for x in (PoseMod.PoseState.keys) do (append PoseKeys ((x.time as integer)/ticksperframe))

						AllKeys = MasterKeys + PoseKeys
						AllKeys = makeUniqueArray AllKeys
						AllKeys = sort AllKeys

						with redraw off
						(
							undo off
							(
								FailedKeys = #()
								for t in AllKeys do
								(
									if (t >= ((animationrange.start as integer)/ticksperframe)) and (t <= ((animationrange.end as integer)/ticksperframe)) then
									(
										sliderTime = t
										try
										(
											PoseMod.updateTreeView()
											
											MinLoad = PoseMod.IndexSkip[PoseMod.MasterState+1] --2
					
											if MinLoad < 0 then 
											(
												--InstPoseSaverR.Flipper.checked = true
												MinLoad = -MinLoad
											
											)else
											(
												--InstPoseSaverR.Flipper.checked = False
											)
											NewMaster = (PoseMod.RawSubMaster - (PoseMod.SubSize*(MinLoad-1)))
											
											PoseMod.setPoseValues PoseMod.poseSaverR.poseListDn.nodes.item[NewMaster].nodes.item[PoseMod.PoseState]
										)
										catch
										(
											Append FailedKeys t
										)
									)
									else()
								)
							)
						)
						
						if FailedKeys[1] != undefined then
						(
							messageBox ("Frame(s) "+(FailedKeys as string)+" could not be updated.")
						)else()
					)
				)else(MessageBox "Please open the Pose Saver modifier")
			)else(MessageBox "Please select an object with a Pose Saver modifier.")
		)else(MessageBox "Please select only one object.")
	),

	/*FnStart*******************************************************
	Function: Updates Selected Character(s) PoseSavers from Library
	*********************************************************FnEnd*/
	fn ReLoadPoses CNT = 
	(	
		clearselection()
		if CNT != undefined then Select CNT
		if selection.count == 1 then
		(
			max modify mode
			PoseMod = undefined
			for m in selection[1].modifiers where classof m == posesaver do (PoseMod = m)
			if PoseMod != undefined then
			(
				if PoseMod.poseSaverR.open then
				(	
					loadPath=("P:\15012_Ollie\_Production\_MasterFiles\_15012_MAST_Common\MAST_COM_Scripts\_PoseSaverXMLs\\"+selection[1].name+".xml")
					
					if doesfileexist loadPath then
					(
						oFile=loadPath
						dotNet.loadAssembly "system.xml"
						PoseMod.xmlDoc=dotNetObject "system.xml.xmlDocument"
						
						PoseMod.xmlDoc.Load oFile
						
						PoseMod.xmlData=PoseMod.xmlDoc.outerXML
			-- 			oFile=openFile loadPath mode:"r"			
			-- 			XMLData=""
			-- 			while not eOf oFile do
			-- 			(
			-- 				XMLData+=readLine oFile
			-- 			)
						(PoseMod.initXML())
						(PoseMod.updateTreeView())
					)else(MessageBox ("No XML Data Found for "+selection[1].name))
				)else(MessageBox "Please open the Pose Saver modifier")
			)else(MessageBox "Please select an object with a Pose Saver modifier.")
		)else(MessageBox "Please select only one object.")
	),
	
	fn checkForCaDef sa val ThisFrame:false = -- checks for custom attribute defs
	(
		def = custAttributes.get sa val -- get the def on this controller
		if def != undefined then -- if there is a def present
		(
			--format "Found custom attribute: %\n" def.name -- format to listener the name of the def that has been found
			getSubAnimsRecurse def ThisFrame -- get any subAnims on the def
			checkForCaDef sa (val + 1) ThisFrame -- check to see if there is another def
		)
	),
	
	fn getSubAnimsRecurse sa ThisFrame:false = -- loops through subAnims starting from the given controller
	(
		numSubAnims = sa.numSubs -- checks how many subAnims there are
		for x = 1 to numSubAnims do -- loops through the number of subAnims
		(
			newSa = getSubAnim sa x -- gets one of the subAnims
			try
			(
				if ThisFrame then
				(
					addNewKey newSa currenttime
				)else
				(
					addNewKey newSa animationRange.start -- adds a new key to the subAnim at the start of the animation range
					addNewKey newSa animationRange.end -- adds a new key to the subAnim at the end of the animation range
				)
				--format "Keys added to %\n" newSa.name -- formats the name of the subAnim that has been found
				checkForCaDef newSa 1 ThisFrame -- checks to see if there is a custom attribute def on the subAnim
				getSubAnimsRecurse newSa ThisFrame -- calls this function again to see if there are more subAnims on this subAnim
			)
			catch()
		)
	),

	/*FnStart*******************************************************
	Function: Loads Scene Characters into Tool
	*********************************************************FnEnd*/
	fn LoadChars =
	(
		CharLayer = LayerManager.getLayerFromName "CHAR"
		if CharLayer == undefined then
		(
			LayerManager.newLayerFromName "CHAR"
			CharLayer = LayerManager.getLayerFromName "CHAR"
			OllieLayer = LayerManager.getLayerFromName "Ollie"
			OllieLayer.setParent CharLayer
		)else()
		
		CharCount = CharLayer.getnumchildren()
		CharAr = #()
		for x = 1 to CharCount do append CharAr ((CharLayer.getChild x).name)
		_Ollie_ToolsR._OllieRigsLB.items = CharAr
		_Ollie_ToolsR._OllieRigsLB.selection = 0
	),

	/*FnStart*******************************************************
	Function: Update Pose Saver
	*********************************************************FnEnd*/
	fn LoadPoseSavers=
	(
		CntLayer = (LayerManager.getLayerFromName ((Ollie_Tools._Ollie_ToolsR._OllieRigsLB.selected)+"_CNT"))
		
		CntLayer.Nodes &CntAr
		
		CurrentOBJs = CntAr
		
		Ollie_Tools.PoseSaverCNTs = #()

		for obj in CntAr do
		(
			for m in obj.modifiers do
			(
				if classOf m==PoseSaver do append Ollie_Tools.PoseSaverCNTs obj
			)
		)
		
		
		
		SaverCNTNames = (for x in Ollie_Tools.PoseSaverCNTs collect x.name)
		LBPoseNames = #()
		MatchAr = #("Head","Waist","HandR","HandL","FootR","LegR","LegL","EyeR","EyeL","EyebrowR","EyebrowL","Mouth","EarR","EarL","Coin")
		
		for x in SaverCNTNames do
		(
			SplitName = filterstring x "_"
			For y in MatchAr do
			(
				NameIndex = findItem Splitname y
				if NameIndex != 0 then (Append LBPoseNames SplitName[NameIndex])
			)
		) 
		
		try(
			LegIn = findItem LBPoseNames "LegL"
			deleteItem LBPoseNames LegIn
			insertItem "FootL" LBPoseNames LegIn 
		)catch()
		
		_Ollie_ToolsR._OllieRigsPoseSaverLB.items = LBPoseNames
		
	),

	/*FnStart*******************************************************
	Function: Delete Selected Rig
	*********************************************************FnEnd*/
	fn DeleteRig Charname=
	(
		CharacterLayer = LayerManager.getLayerFromName Charname

		fn GetCharObjs CharacterLayer =
		(
			SubLayerCount = CharacterLayer.getnumchildren()
			CharObjAr = #()
			for x = 1 to SubLayerCount do 
			(
				SubLayer = CharacterLayer.getChild x
				
				SubLayer.nodes &theNodes
				join CharObjAr theNodes
			)
			return CharObjAr
		)

		CharObjs = GetCharObjs CharacterLayer 


		FirstDeleteAr = #()

		for x in CharObjs do 
		(
			if x.baseobject[8] != undefined then
			(
				if x.baseobject[8][2] != undefined then
				(
					if classof x.baseobject[8][2].controller == point3_script do append FirstDeleteAr x
				)
			)
		)

		delete FirstDeleteAr

		CharObjs = GetCharObjs CharacterLayer 

		delete CharObjs
		
		LayerManager.deleteLayerHierarchy (_Ollie_ToolsR._OllieRigsLB.selected) forceDelete:true
		
	),


        /*FnStart*******************************************************
	Function: Isolate Face for Lipsync
	*********************************************************FnEnd*/	
	fn LipSyncIsolateFn Charname =
	(
		CharacterLayer = LayerManager.getLayerFromName Charname
		fn GetCharObjs CharacterLayer =
		(
			SubLayerCount = CharacterLayer.getnumchildren()
			CharObjAr = #()
			for x = 1 to SubLayerCount do 
			(
				SubLayer = CharacterLayer.getChild x
				
				SubLayer.nodes &theNodes
				join CharObjAr theNodes
			)
			return CharObjAr
		)

		CharObjs = GetCharObjs CharacterLayer 
		
		LipSyncParents = #()
		
		for x in CharObjs do
		(
			if (findstring x.name "Head_BN_Main" != undefined) do Append LipSyncParents x
			if (findstring x.name "Face_CNT" != undefined) do Append LipSyncParents x
			if (findstring x.name "PT_FaceAnchor" != undefined) do Append LipSyncParents x
			if (findstring x.name "UpperBody_GEO_Main" != undefined) do Append LipSyncParents x
		)
		
		LipSyncObjs = #()

		For x in LipSyncParents do
		(
			Join LipSyncObjs (Ollie_Tools.collectMyChildren x)
		)
		
		Select LipSyncObjs

		actionMan.executeAction 0 "197"  -- Tools: Isolate Selection

		clearselection()
	),
	
	/*FnStart*******************************************************
	Function: Updates EXR Settings
	*********************************************************FnEnd*/
	fn FNExrSetup =
	(
		fopenexr.SetCompression 4							--Compression: PIZ
		fopenexr.setLayerOutputFormat 0 1				--Format: Half Float (16 bits per channel)
		fopenexr.setLayerOutputType 0 0					--Type: RGBA
		fopenexr.setSaveScanline false						--Storage Type: Tiles
		fopenexr.setSaveRegion false							--Image Region: Save Full Image
		fopenexr.setAutoAddRenderElements true		--Auto Add Render Elements
	),
	
	/*FnStart*******************************************************
	Function: Creates Approval Dir if Needed
	*********************************************************FnEnd*/
	fn FNCreateApprovalDir =
	(
		if Ollie_Tools.ApprovalDir==undefined then
		(
			Ollie_Tools.ApprovalDir=@"P:\15012_Ollie\_Production\_Approvals\15012_APP_"
			Epname=filterstring Ollie_Tools.Filename "_"
			EpNumFull=Epname[1]
			EpNum=Substring EpNumFull 1 3
			AppDir=Ollie_Tools.ApprovalDir+EpNum
			GetAppDir=getDirectories  (AppDir+@"\*")
			if GetAppDir.count!=0 then
			(
				ABCheck=Substring EpNumFull 4 1
				if ABCheck=="A" then
				(
					Ollie_Tools.ApprovalDir= GetAppDir [1]
				)
				else
				(
					Ollie_Tools.ApprovalDir= GetAppDir [2]
				)
				Ollie_Tools.EXRApprovalDir=Ollie_Tools.ApprovalDir+Ollie_Tools.Filename+@"\"
				if doesfileexist Ollie_Tools.EXRApprovalDir !=true do
				(
					makedir Ollie_Tools.EXRApprovalDir 
				)
				Ollie_Tools.PBFile=(Ollie_Tools.ApprovalDir + Ollie_Tools.Filename+"-Review.mov")

				if doesFileExist Ollie_Tools.PBFile==true then
				(
					Ollie_Tools._Ollie_ToolsR._ViewPBBt.enabled=true
				)
				else
				(
					Ollie_Tools._Ollie_ToolsR._ViewPBBt.enabled=false
				)
				Ollie_Tools._Ollie_ToolsR._OpDirBt.enabled=true
				Ollie_Tools.RenderGo()
			)
			else
			(
				Ollie_Tools.ApprovalDir=undefined
				Ollie_Tools._Ollie_ToolsR._MakePBBt.enabled=false
				Ollie_Tools._Ollie_ToolsR._OpDirBt.enabled=false
				messagebox "Approval Directories have not been created.\nNotify Dennis." title:"Error"
			)
			
		)
		else
		(
			Ollie_Tools.EXRApprovalDir=Ollie_Tools.ApprovalDir+Ollie_Tools.Filename+@"\"
				if doesfileexist Ollie_Tools.EXRApprovalDir !=true do
				(
					makedir Ollie_Tools.EXRApprovalDir 
				)
				Ollie_Tools.PBFile=(Ollie_Tools.ApprovalDir + Ollie_Tools.Filename+"-Review.mov")

				if doesFileExist Ollie_Tools.PBFile==true then
				(
					Ollie_Tools._Ollie_ToolsR._ViewPBBt.enabled=true
				)
				else
				(
					Ollie_Tools._Ollie_ToolsR._ViewPBBt.enabled=false
				)
				Ollie_Tools._Ollie_ToolsR._OpDirBt.enabled=true
				Ollie_Tools.RenderGo()
		)
			
			

	),
	
	/*FnStart*******************************************************
	Function: Sets Render Settings
	*********************************************************FnEnd*/
	fn FNRenderCheck =
	(
		if EXRCheckfileCount.count>0 then
		(
			if querybox "A previous EXR sequence exists.\nWould you like to overwrite it?" then
			(
				
				Ollie_Tools.RenderGo()
			)
			else
			(
				Ollie_Tools.nukeit()
			)
		)
		else
		(
			Ollie_Tools.RenderGo()
		)
	),
	
	/*FnStart*******************************************************
	Function: Render Fuction
	*********************************************************FnEnd*/
	fn RenderGo =
	(
		if renderSceneDialog.isOpen() do renderSceneDialog.close() 
		EXRCheckfileCount=getfiles (Ollie_Tools.EXRApprovalDir+@"*")
		for i =1 to EXRCheckfileCount.count do
		(
			deletefile EXRCheckfileCount[i]
		)
		viewport.setCanvasNavigationMode false --Turns off 2D Pan Zoom Mode
		viewport.setType #view_camera
		outpath=Ollie_Tools.EXRApprovalDir+(getFilenameFile maxfilename)+"_.exr"
-- 		preRendScript= @"P:\15012_Ollie\_Production\_MasterFiles\_15012_MAST_Common\MAST_COM_Scripts\COM_SCRIPT_OllieZeroRenderFix.ms" 
-- 		usePreRendScript=true
		renderwidth=1920
		renderheight=1080
		rendOutputFilename = outpath
-- 		rendTimeType = 2
		rendSaveFile = true
		renderers.current=Default_Scanline_Renderer()
-- 		renderSceneDialog.update()
		
		if queryBox "Do You Want to submit to the Farm?" beep:false then
		(
			Ollie_Tools._Ollie_ToolsR.EXRCheck.active=true
			rendTimeType = 3
			--rendFileNumberBase=-1
			renderSceneDialog.update()
			m = NetRender.GetManager()
			m.connect #manual "licensing"
			serverGroup = m.getservers filter:#group key:"Expanse"
			_FrameStart = (animationrange.start-1)
			_FrameEnd = animationrange.end
			_Priority = 50
			_suspended = false
			_JobType = "Ollie Approval Render"
			IDNum = (random 0 9999 as string) 
			_jobName = "[" + _JobType + "] - " + (getFilenameFile maxfilename) + " - ID#" + IDNum 
			job = m.newjob()
			job.name = _jobName
			job.priority = _Priority
			job.suspended = _suspended
			job.FromFrame = _FrameStart
			job.ToFrame = _FrameEnd
			if queryBox "Is this Job Critical?" beep:false then
			(
				job.priority = 0
			)
			job.submit Servers:serverGroup
		)
		else
		(
			rendTimeType = 2
			renderSceneDialog.update()
			max quick render
			
-- 			renderSceneDialog.update()
-- 			x=UIAccessor.GetPopupDialogs()
-- 			if (UIAccessor.GetWindowText  x[1])!="Ollie_Tools" do
-- 			(
-- 				UIAccessor.CloseDialog x[1]
-- 			)
			Ollie_Tools.nukeIt()
		)
		--usePreRendScript=false
        rendSaveFile = false
		rendTimeType = 1
-- 		rendFileNumberBase=0
-- 		Ollie_Tools.nukeIt()
	),
	
	/*FnStart*******************************************************
	Function: Makes Nuke Video File
	*********************************************************FnEnd*/
	fn nukeIt =
	(
		if doesfileexist (Ollie_Tools.EXRApprovalDir) == true then
		(
			SFrame=(animationrange.start.frame)as integer
			EFrame=(animationrange.end.frame)as integer
			rangelength=(EFrame-SFrame+1)
			EXRCheckfileCount=getfiles (Ollie_Tools.EXRApprovalDir+@"*")
			
			if (EXRCheckfileCount.count==rangelength) do
			(
				if progNuke!=undefined then
				(
					
			
					Ollie_Tools._Ollie_ToolsR.MakeVidCheck.active=true
					
					DateTime = getLocalTime()
					GetDate = (DateTime[2]as string) + "_" + (DateTime[4]as string) + "_" + (DateTime[1]as string)	-- MM_DD_YYYYY
					AP="AM"
					if (DateTime[5])>12 do
					(
						DateTime[5]-=12
						AP="PM"
					)
					GetTime = (DateTime[5]as string) + ":" + (DateTime[6]as string)
					TimeString = GetDate + "-" + GetTime+"_"+AP
					
					
					fn MakeQT TimeString=
					(
						NSSound = kfaniToolPath+@"Ollie_Tools\NukeTemplateSound.nk"		-- requires input and output
						NSNoSound = kfaniToolPath+@"Ollie_Tools\NukeTemplateNoSound.nk"		-- requires input and output
						filedir=(substituteString Ollie_Tools.EXRApprovalDir "\\" "/")
						savedir=(substituteString Ollie_Tools.ApprovalDir "\\" "/")
						_Name_String = Ollie_Tools.Filename
						renSeq = getfiles (filedir + _Name_String+"_*.EXR")
						_Image_String = (substring renseq[1] 1 (renseq[1].count - 9)) + "_####.EXR"
						_Audio_String =prosound.name 1
						StartF = ((substring renSeq[1] (renSeq[1].count-7)4) as integer) as string
						_Flength = (StartF + "," + (RenSeq.count + ((StartF as integer))-1) as string)
						_output_string = savedir + _Name_String + "-Review.mov"
						Ollie_Tools.PBFile=_output_string
						NukeString=undefined
						if prosound.numtracks() ==0 then
						(
							NukeString = (" -x " + NSNoSound + " " + _Image_String + " " + _Output_String + " " + _Name_String + " " + sysinfo.username + " " + TimeString + " " + _Flength)
						)
						else
						(
							NukeString = (" -x " + NSSound + " " + _Image_String + " " + _Output_String + " " + _Audio_String + " " + _Name_String + " " + sysinfo.username + " " + TimeString + " " + _Flength)
						)
						shellLaunch progNuke NukeString
					)
					MakeQT TimeString
				)
				else
				(
					messagebox "Nuke is not installed.\nContact Darren Locke for information." title:"Notice"
				)
			)
		)
		else
		(
			messagebox "Unable to Locate EXR files.\nTry Making another PlayBlast" title:"Error"
		)
		
	),
	
	/*FnStart*******************************************************
	Function: Check for existing Output files
	*********************************************************FnEnd*/
	fn filecheck =
	(
		Ollie_Tools.ApprovalDir=@"P:\15012_Ollie\_Production\_Approvals\15012_APP_"
		Namecheck=getFilenameFile maxfilename
		if Namecheck !="" do
		(
			Ollie_Tools.Filename = getFilenameFile maxfilename
			Epname=filterstring Ollie_Tools.Filename "_"
			EpNumFull=Epname[1]
			EpNum=Substring EpNumFull 1 3
			ABCheck=Substring EpNumFull 4 1
			AppDir=Ollie_Tools.ApprovalDir+EpNum
			GetAppDir=getDirectories  (AppDir+@"\*")
			if GetAppDir.count!=0 then
			(
				
				if ABCheck=="A" then
				(
					Ollie_Tools.ApprovalDir= GetAppDir [1]
					Ollie_Tools.EXRApprovalDir=Ollie_Tools.ApprovalDir+Ollie_Tools.Filename+@"\"
					Ollie_Tools._Ollie_ToolsR._MakePBBt.enabled=true
					Ollie_Tools._Ollie_ToolsR._OpDirBt.enabled=true
				)
				else
				(
					if GetAppDir.count==2 then
					(
						Ollie_Tools.ApprovalDir= GetAppDir [2]
						Ollie_Tools.EXRApprovalDir=Ollie_Tools.ApprovalDir+Ollie_Tools.Filename+@"\"
						Ollie_Tools._Ollie_ToolsR._MakePBBt.enabled=true
						Ollie_Tools._Ollie_ToolsR._OpDirBt.enabled=true
					)
					else
					(
						Ollie_Tools.ApprovalDir=undefined
						Ollie_Tools._Ollie_ToolsR._MakePBBt.enabled=false
						Ollie_Tools._Ollie_ToolsR._ViewPBBt.enabled=false
						Ollie_Tools._Ollie_ToolsR._OpDirBt.enabled=false
						messagebox "Approval Directories have not been created.\nNotify Dennis." title:"Error"
					)
						
				)
				
				
				Ollie_Tools.PBFile=(Ollie_Tools.ApprovalDir + Ollie_Tools.Filename+"-Review.mov")

				if doesFileExist Ollie_Tools.PBFile==true then
				(
					Ollie_Tools._Ollie_ToolsR._ViewPBBt.enabled=true
				)
				else
				(
					Ollie_Tools._Ollie_ToolsR._ViewPBBt.enabled=false

				)
			)
			else
			(
				Ollie_Tools.ApprovalDir=undefined
				Ollie_Tools._Ollie_ToolsR._MakePBBt.enabled=false
				Ollie_Tools._Ollie_ToolsR._ViewPBBt.enabled=false
				Ollie_Tools._Ollie_ToolsR._OpDirBt.enabled=false
				messagebox "Approval Directories have not been created.\nNotify Dennis." title:"Error"
			)
		)
		
	),
	
	/*FnStart*******************************************************
	Function: Gets Fix Scripts
	*********************************************************FnEnd*/
	fn getFixes=
	(
		case Ollie_Tools._OllieFixR._FixType.selection of
		(
			(1):(Ollie_Tools._fixoutPath = @"P:\15012_Ollie\_Production\_MasterFiles\_15012_MAST_Common\MAST_COM_Scripts\50_ANIMATION\")
			(2):(Ollie_Tools._fixoutPath = @"P:\15012_Ollie\_Production\_MasterFiles\_15012_MAST_Common\MAST_COM_Scripts\20_TEXTURING\")
			(3):(Ollie_Tools._fixoutPath = @"P:\15012_Ollie\_Production\_MasterFiles\_15012_MAST_Common\MAST_COM_Scripts\10_MODELING\")
-- 			(4):(_Outpath = )
-- 			(5):(_Outpath = )
		)
		Ollie_Tools._FixList= getFiles (_fixoutPath+"*")
	),
	
	/*FnStart*******************************************************
	Function: Gets Fix Names
	*********************************************************FnEnd*/
	fn FixUISort = 
	(
		for i = 1 to Ollie_Tools._FixList.count do
		(
			countval=(filterstring Ollie_Tools._FixList[i] @"\")
			scriptname=(filterstring Ollie_Tools._FixList[i] @"\")[countval.count]
			scriptname=(filterstring scriptname "_")
			
			Ollie_Tools._FixListUI[i]=(filterstring scriptname[3] ".")[1]
		)
	),
	
	/*FnStart*******************************************************
	Function: Fix UI
	*********************************************************FnEnd*/
	fn _fixUI =
	(
		rollout _OllieFixR "Ollie Fix Scripts"
		(
			local btWid=(_OllieFixR.width-15)
			dropdownlist _FixType items:Ollie_Tools._FixTypeList  width:btWid pos:[8,5]
			listbox _fixScripts width:btWid height:5 pos:[_FixType.pos.x,_FixType.pos.y+22]
			button _goFix "Fix" width:btWid pos:[_FixType.pos.x,_fixScripts.pos.y+_fixScripts.height+2]
			button _edit "Edit" width:(BtWid/2) pos:[_FixType.pos.x,_goFix.pos.y+22]
			button _lib "Dir" width:(BtWid/2) pos:[_edit.pos.x+(BtWid/2)+1,_edit.pos.y]
			
			on _FixType selected x do
			(
				Ollie_Tools._FixListUI = #()
				Ollie_Tools.getFixes()
				Ollie_Tools.FixUISort()
				_fixScripts.items=Ollie_Tools._FixListUI
				_fixScripts.selection=0
			)
			
			on _goFix pressed do
			(
				if _fixScripts.selection!=0 then
				(
					::filein Ollie_Tools._FixList[_fixScripts.selection]
				)
				else
				(
					messagebox "Select a Fix Script" title:"Error"
				)
			)
			
			on _edit pressed do
			(
				if _fixScripts.selection==0 then
				(
					messageBox "No Script selected." title:"Error"
				)
				else
				(
					edit Ollie_Tools._FixList[_fixScripts.selection]
				)
			)
			
			on _lib pressed do
			(
				shelllaunch Ollie_Tools._fixoutPath ""
			)
			
			
			on _OllieFixR open do
			(
				Ollie_Tools._FixListUI = #()
				Ollie_Tools.getFixes()
				Ollie_Tools.FixUISort()
				_fixScripts.items=Ollie_Tools._FixListUI
				_fixScripts.selection=0
				
				if sysinfo.username!="j.aitken" and sysinfo.username!="a.ali" do
				(
					_edit.visible=false
					_lib.visible=false
					_OllieFixR.height=126
				)
			)
		)

	),
	
	/*FnStart*******************************************************
	Function: Main UI
	*********************************************************FnEnd*/
	fn UI =
	(
		rollout _Ollie_ToolsR "Ollie_Tools"
		(
			local btWid=(_Ollie_ToolsR.width-15)
			local AbtWid=(btWid/3)-4
			local ButtonsOn = false
			
			
			
			groupbox _ListBoxGB "" Width:btWid height:190 align:#center
			listbox _OllieRigsLB "Scene Characters:" items:#("","") pos:[_ListBoxGB.pos.x+6,_ListBoxGB.pos.y+8] width:(btWid-12) height:5 
			Multilistbox _OllieRigsPoseSaverLB "Pose Savers:" items:#("","") pos:[_OllieRigsLB.pos.x,_OllieRigsLB.pos.y+_OllieRigsLB.height+2] width:(btWid-12) height:5

			groupbox _showhideGB "Geo Tools" Width:btWid height:62 pos:[_ListBoxGB.pos.x,_ListBoxGB.pos.y+_ListBoxGB.height+2]
			Button _hideGeoBt "Hide" width:75 height:20 pos:[_showhideGB.pos.x+6,_showhideGB.pos.y+15]
			Button _showGeoBt "Show" width:75 height:20 pos:[_hideGeoBt.pos.x+75,_hideGeoBt.pos.y]-- pos:[_SubCNTsCB.pos.x+30,_PrepSLbt.pos.y]
			CheckButton _IsolateLipSyncBt "Lip-Sync" width:150 height:20 enabled:ButtonsOn pos:[_hideGeoBt.pos.x,_hideGeoBt.pos.y+21]
						
			groupbox _AnimGB "Animation" Width:btWid height:40 pos:[_showhideGB.pos.x,_showhideGB.pos.y+_showhideGB.height+2]
			Button _PrepSLbt "Save" width:75 height:20 enabled:ButtonsOn pos:[_AnimGB.pos.x+6,_AnimGB.pos.y+15]
			Button _Loadbt "Load" width:75 height:20 enabled:ButtonsOn pos:[_PrepSLbt.pos.x+75,_PrepSLbt.pos.y]-- pos:[_SubCNTsCB.pos.x+30,_PrepSLbt.pos.y]
			
			groupbox _PosesGB "Pose Savers" Width:btWid height:62 pos:[_AnimGB.pos.x,_AnimGB.pos.y+_AnimGB.height+2]
			Button _ReKeySelPSBt "Re-Pose Sel." width:75 height:20  enabled:ButtonsOn pos:[_PosesGB.pos.x+6,_PosesGB.pos.y+15]
			Button _ReKeyAllPSBt "Re-Pose All" width:75 height:20 enabled:ButtonsOn pos:[_ReKeySelPSBt.pos.x+75,_ReKeySelPSBt.pos.y]-- pos:[_SubCNTsCB.pos.x+30,_PrepSLbt.pos.y]
			Button _ReLoadSelPSBt "Re-Load Sel." width:75 height:20  enabled:ButtonsOn pos:[_PosesGB.pos.x+6,_ReKeyAllPSBt.pos.y+21]
			Button _ReLoadAllPSBt "Re-Load All" width:75 height:20 enabled:ButtonsOn pos:[_ReLoadSelPSBt.pos.x+75,_ReLoadSelPSBt.pos.y]
			
			groupbox _KeyGB "Rig Tools" Width:btWid height:62 pos:[_PosesGB.pos.x,_PosesGB.pos.y+_PosesGB.height+2]			
			Button _KeyAllBt "Key All" width:75 height:20  enabled:ButtonsOn pos:[_KeyGB.pos.x+6,_KeyGB.pos.y+15]
			Button _ResetAllBt "Reset CNTs" width:75 height:20 enabled:ButtonsOn pos:[_KeyAllBt.pos.x+75,_KeyAllBt.pos.y]
			Button _DeleteRig "Delete Character" width:150 height:20 enabled:ButtonsOn pos:[_KeyAllBt.pos.x,_KeyAllBt.pos.y+21]
			
			groupbox _AppGB "Approval PlayBlast" Width:btWid height:40 pos:[_KeyGB.pos.x,_KeyGB.pos.y+_KeyGB.height+2]
			button _MakePBBt "Make" width:AbtWid align:#center enabled:false pos:[_AppGB.pos.x+6,_AppGB.pos.y+15]
			button _ViewPBBt "View" width:AbtWid align:#center enabled:false pos:[_MakePBBt.pos.x+AbtWid,_MakePBBt.pos.y]
			button _OpDirBt "Dir" width:AbtWid align:#center enabled:false pos:[_ViewPBBt.pos.x+AbtWid,_ViewPBBt.pos.y]
			
			button _launchFix "Ollie Fix Scripts" width:btWid pos:[_AppGB.pos.x,_AppGB.pos.y+_AppGB.height+2]
			
			timer MakeVidCheck interval:1000 active:false
			timer EXRCheck interval:1000 active:false
			--unused
			CheckButton _SubCNTsCB "Sub" checked:false width:30 height:20 enabled:ButtonsOn visible:false pos:[0,0]--pos:[_PrepSLbt.pos.x+45,_PrepSLbt.pos.y] 
			CheckButton _LoadSubCNTsCB "Sub" checked:false width:30 height:20 enabled:ButtonsOn visible:false pos:[0,0]--pos:[_Loadbt.pos.x+45,_PrepSLbt.pos.y]
			CheckButton _ReKeyHeadCB "Head" checked:false width:30 height:20 enabled:ButtonsOn visible:false pos:[0,0]
			CheckButton _ReKeyBodyCB "Body" checked:false width:30 height:20 enabled:ButtonsOn visible:false pos:[0,0]
			dropdownlist _SavedPosesDDL "Saved Poses" enabled:ButtonsOn visible:false
			
			fn ButtonsEnabled=
			(
				for x in Ollie_Tools._Ollie_ToolsR.controls do 
				(
					if x.name!="_MakePBBt" and x.name!="_ViewPBBt" and x.name!="_OpDirBt" do x.enabled = true
				)
			)
			
			on _OllieRigsLB selected item do
			(
				ButtonsEnabled()
				Ollie_Tools.LoadPoseSavers()
			)

			on _hideGeoBt pressed do
			(
				xgeo=($*'-xtra' as array)
				for x in xgeo do
				(
					hide x
				)
			)

			on _showGeoBt pressed do
			(
				xgeo=($*'-xtra' as array)
				for x in xgeo do
				(
					unhide x
				)
			)
			
			on _IsolateLipSyncBt changed state do
			(
				if State == on then
				(
					Ollie_Tools.LipSyncIsolateFn _OllieRigsLB.selected
				)else
				(
					actionMan.executeAction 0 "261"  -- Tools: End Isolate
				)
			)
			
			on _PrepSLbt pressed do 
			(
				if _OllieRigsLB.selection != 0 then
				(
					CntLayer = (LayerManager.getLayerFromName ((_OllieRigsLB.selected)+"_CNT"))
					SubCntLayer = (LayerManager.getLayerFromName ((_OllieRigsLB.selected)+"_SubCNT"))
					if ((CntLayer != undefined) and (SubCntLayer != undefined)) then
					(
						CntLayer.Nodes &CntAr
						SubCntLayer.Nodes &SubCntAr
						ObjAr = #()
						if _SubCNTsCB.checked then ObjAr = (CntAr + SubCNTAr) else (ObjAr = CntAr)
						
						for x in ObjAr do for i = 3 to 5 do	Ollie_Tools.getSubAnimsRecurse x[i]
							
						clearselection
						
						select ObjAr
						
						actionMan.executeAction 0 "562"
						
					)else
					(
						Messagebox "Improper Layers"
					)
				)else
				(
					Messagebox "Please select a scene character."
				)
			)
			
			on _Loadbt pressed do 
			(
				if _OllieRigsLB.selection != 0 then
				(
					CntLayer = (LayerManager.getLayerFromName ((_OllieRigsLB.selected)+"_CNT"))
					SubCntLayer = (LayerManager.getLayerFromName ((_OllieRigsLB.selected)+"_SubCNT"))
					if ((CntLayer != undefined) and (SubCntLayer != undefined)) then
					(
						CntLayer.Nodes &CntAr
						SubCntLayer.Nodes &SubCntAr
						ObjAr = #()
						if _LoadSubCNTsCB.checked then ObjAr = (CntAr + SubCNTAr) else (ObjAr = CntAr)
						
						--for x in ObjAr do for i = 3 to 5 do	Ollie_Tools.getSubAnimsRecurse x[i]
							
						clearselection
						
						select ObjAr
						
						actionMan.executeAction 0 "561"
						
					)else
					(
						Messagebox "Improper Layers"
					)
				)else
				(
					Messagebox "Please select a scene character."
				)
			)
			
			on _ReKeySelPSBt pressed do
			(
				Items = _OllieRigsPoseSaverLB.selection as array
				For x in Items do
				(
					Ollie_Tools.ReKeyPoses Ollie_Tools.PoseSaverCNTs[x]
				)
			)
			
			on _ReKeyAllPSBt pressed do
			(
				for x in Ollie_Tools.PoseSaverCNTs do Ollie_Tools.ReKeyPoses x

			)
			
			on _ReLoadSelPSBt pressed do
			(
				Items = _OllieRigsPoseSaverLB.selection as array
				For x in Items do
				(
					Ollie_Tools.ReLoadPoses Ollie_Tools.PoseSaverCNTs[x]
				)
			)
			
			on _ReLoadAllPSBt pressed do
			(
				for x in Ollie_Tools.PoseSaverCNTs do Ollie_Tools.ReLoadPoses x

			)
	
			on _KeyAllBt pressed do
			(
				if _OllieRigsLB.selection != 0 then
				(
					CntLayer = (LayerManager.getLayerFromName ((_OllieRigsLB.selected)+"_CNT"))
					SubCntLayer = (LayerManager.getLayerFromName ((_OllieRigsLB.selected)+"_SubCNT"))
					if ((CntLayer != undefined) and (SubCntLayer != undefined)) then
					(
						CntLayer.Nodes &CntAr
						SubCntLayer.Nodes &SubCntAr
						ObjAr = #()
						if _SubCNTsCB.checked then ObjAr = (CntAr + SubCNTAr) else (ObjAr = CntAr)
						
						for x in ObjAr do for i = 3 to 5 do	Ollie_Tools.getSubAnimsRecurse x[i] ThisFrame:true					
					)else
					(
						Messagebox "Improper Layers"
					)
				)else
				(
					Messagebox "Please select a scene character."
				)
			)
			
			on _ResetAllBt pressed do
			(
				CntLayer = (LayerManager.getLayerFromName ((_OllieRigsLB.selected)+"_CNT"))
				CntLayer.Nodes &CntAr
				select CntAr
				macros.run "Characters" "AssumeSkinPose"
			)
			
			on _DeleteRig pressed do
			(
				MessageStr = ("Character \""+_OllieRigsLB.selected+"\" will be permanently deleted from the scene.")
				if querybox MessageStr title:"Are you sure?" then
				(
					Ollie_Tools.DeleteRig _OllieRigsLB.selected
					Ollie_Tools.LoadChars()
				)else()
			)
			
			on _MakePBBt pressed do
			(
				if querybox "Would you like to send this animated sequence out for approval?" then
				(
					if progNuke !=undefined then
					(
						Namecheck=getFilenameFile maxfilename
						if Namecheck=="" then
						(
							messagebox "Save your File first." title:"Error"
						)
						else
						(
							Ollie_Tools.Filename = Namecheck
							Camcheck=#()
							for o in objects do
							(
								if superclassof o==camera then
								(
									append Camcheck o.name
								)
							)
							if Camcheck.count>0 then
							(
								if (doesfileexist Ollie_Tools.PBFile)==true do
								(
									deletefile Ollie_Tools.PBFile
								)
								xgeo=($*'-xtra' as array)
								for x in xgeo do
								(
									unhide x
								)
								Ollie_Tools.FNExrSetup()
								Ollie_Tools.FNCreateApprovalDir()
							)
							else
							(
								messagebox "No Camera Detected." title:"Error"
							)
					)
					
					)
					else
					(
						messagebox "Nuke is not installed on your system.\nContact Darren Locke for help." title:"Nuke not found"
					)
				)
				else
				(
					Messagebox "Approval Render Aborted."
				)
			)
						
			on _ViewPBBt pressed do
			(
				vid=Ollie_Tools.ApprovalDir + Ollie_Tools.Filename+"-Review.mov"
				if (doesfileexist vid)==true then
				(
					shellLaunch vid ""
				)
				else
				(
					if (doesfileexist Ollie_Tools.PBFile)==true do
					(
						deletefile Ollie_Tools.PBFile
					)
					Ollie_Tools.nukeIt()
				)
			)
						
			on _OpDirBt pressed do
			(
				shellLaunch "explorer.exe" Ollie_Tools.ApprovalDir
			)
			
			on _launchFix pressed do
			(
				try(destroydialog Ollie_Tools._OllieFixR)catch()
				DialPos = GetDialogPos Ollie_Tools._Ollie_ToolsR
				DialPos[1] = (DialPos[1]+Ollie_Tools._Ollie_ToolsR.width+5) as integer
				DialPos[2] = DialPos[2] as integer
				Ollie_Tools._OllieFixR=Ollie_Tools._fixUI()
				createdialog Ollie_Tools._OllieFixR style:#(#style_toolwindow,#style_sysmenu)  width:150 pos:[DialPos[1],DialPos[2]]
			)
			
			on MakeVidCheck tick do
			(
				if (doesFileExist Ollie_Tools.PBFile)==true then
				(
					Ollie_Tools._Ollie_ToolsR._ViewPBBt.enabled=true
					MakeVidCheck.active=false
					--try(shellLaunch Ollie_Tools.PBFile "")catch()
				)
			)
			on EXRCheck tick do
			(
				
				SFrame=(animationrange.start.frame)as integer
				EFrame=(animationrange.end.frame)as integer
				rangelength=(EFrame-SFrame+1)
				EXRCheckfileCount=getfiles (Ollie_Tools.EXRApprovalDir+@"*")
				
				if ((EXRCheckfileCount.count-1)==rangelength) do
				(
					deletefile EXRCheckfileCount[1]
					Ollie_Tools.nukeit()
					EXRCheck.active=false
				)
			)
			on _Ollie_ToolsR open do
			(
				callbacks.addScript #filePostSave Ollie_Tools.Ollie_Tools_postsave_message id:#Ollie_Tools_postsave
				callbacks.addScript #filePreOpenProcess Ollie_Tools.Ollie_Tools_preload_message id:#Ollie_Tools_preload
				callbacks.addScript #filePostOpenProcess Ollie_Tools.Ollie_Tools_postload_message id:#Ollie_Tools_postload
				try(Ollie_Tools.filecheck())catch()
				Ollie_Tools.LoadChars()
			)
			
			on _Ollie_ToolsR close do
			(
				callbacks.RemoveScripts #filePostSave id:#Ollie_Tools_postsave
				callbacks.RemoveScripts #filePreOpenProcess id:#Ollie_Tools_preload
				if Ollie_Tools.cbackloadcheck==0 do
				(
					callbacks.RemoveScripts #filePostOpenProcess id:#Ollie_Tools_postload
				)
				Ollie_Tools._Ollie_ToolsR=undefined
				try(destroydialog Ollie_Tools._OllieFixR)catch()
				Ollie_Tools._OllieFixR=undefined
			)
		)
	),
	
	fn run PosX PosY=
	(
		if _Ollie_ToolsR==undefined then
		(
			_Ollie_ToolsR=UI()
			createDialog  _Ollie_ToolsR pos:[PosX,PosY] style:#(#style_toolwindow,#style_sysmenu) width:177
		)
		else
		(
			destroyDialog   _Ollie_ToolsR
			Ollie_Tools._Ollie_ToolsR=undefined
		)	
	)
	
)
Ollie_Tools=Ollie_Tools()
