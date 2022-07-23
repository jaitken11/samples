/*HeaderStart*******************************************************
Tool Name:	TT ToonShader Setup Script
Created By:	Josh Aitken
Company:	Keyframe Digital
E-Mail:	******
Start Date:	07/20/2016
Last Updated:	07/22/2016

Disclaimer:
This script has been tested to the best of the author's ability. Use at your own risk.
Any damage caused by this script is not the responsibility of the author.

Purpose:
	This auto coverts all the shaders in scene to the appropriate Final Toon shaders,
	sets up VRay and FinalToon, and makes sure all render paths are correct for the shot.

History:
	

To Do:
	

Bugs:
	

Notes:
	

Tested in:
	Max 2016 SP2

Tests:
	TTBillboard.run()

*********************************************************HeaderEnd*/

try(destroyDialog TTBillboard._TTBillboardR)catch()

struct TTBillboard
(
	/*Declare Variables*/
	_TTBillboardR=undefined,
	MasterArray=#(),
	hidegeo=#(),
	
	/*FnStart*******************************************************
	Function: Render Setup
	*********************************************************FnEnd*/
	fn RenderSetupFN =
	(
		viewport.setCanvasNavigationMode false --Turns off 2D Pan Zoom Mode
		viewport.setType #view_camera
		outpath=(maxfilepath+(getFilenameFile maxfilename) as string)
		if (doesFileExist outpath)==false do
		(
			makedir (outpath+@"\")
		)
		savepath=outpath+@"\"+(getFilenameFile maxfilename)+"-EXP_.exr"
		renderwidth=1920
		renderheight=1080
		rendTimeType = 1
		rendSaveFile = false
		rendOutputFilename=savepath
		VRy=VRay output_on:false twoLevel_threshold:0.05 options_glossyEffects:false twoLevel_fineSubdivs:12 twoLevel_bucket_width:24 twoLevel_bucket_height:24 Effectsoptions_hiddenLights:false options_probabilisticLights:false options_reflectionRefraction:false gi_on:false imageSampler_type:1
		renderers.current=VRy
		renderSceneDialog.update()
	),
	
	/*FnStart*******************************************************
	Function: Opens Environment Dialog
	*********************************************************FnEnd*/
	fn EnVOpenFN=
	(
		envEffectsDialog.Open()
		if tabbedDialogs.isOpen #envEffects do 
		(
			tabbedDialogs.setCurrentPage #envEffects #(517034860, 435433537)
		)
	),
	
	/*FnStart*******************************************************
	Function: Opens RenderElements Dialog
	*********************************************************FnEnd*/
	fn RendElOpenFN=
	(
		renderSceneDialog.open()
		if tabbedDialogs.isOpen #render do 
		(
			tabbedDialogs.setCurrentPage #render #(1547006576, 1564889954)
		)
	),
	
	/*FnStart*******************************************************
	Function: Unhides all VRayToon Geo
	*********************************************************FnEnd*/
	fn showMasterArrayFN =
	(
		for i =1 to TTBillboard.hidegeo.count do
		(
			unhide TTBillboard.hidegeo[i]
		)
	),
	
	/*FnStart*******************************************************
	Function: 	Sorts Shot Geo for known Flags and sorts Geo into
				appropriate Vray Toon Elements
	*********************************************************FnEnd*/
	fn MakeOutlinesFN =
	(
		atmocount=numAtmospherics
		for i =1 to atmocount do
		(
			deleteAtmospheric 1
		)
		
		--Groups and Creates Sets for Environment Outline
		ENVIOutlineArray=$ENVI_GEO_OUTLINE* as array
		if ENVIOutlineArray.count>0 do 
		(
			append TTBillboard.MasterArray ENVIOutlineArray
			ENVIVRT = VrayToon name:"VRayToonSETSOutline" color:(color 255 255 255) excludeType:1 normalThreshold:0.0 excludeList:ENVIOutlineArray
			addAtmospheric ENVIVRT
		)
		
		/*Groups and Creates Sets for Characters*/
		if $CHAR_STOTZ_CNT_Root!=undefined do
		(
			STOTZOutlineList=$CHAR_STOTZ_GEO_*_OUT as array
			append TTBillboard.MasterArray STOTZOutlineList
			STOTZlist1 = VrayToon name:"VRT_STOTZ_Outline" color:(color 255 255 255) hideInnerEdges:True excludeType:1 excludeList:STOTZOutlineList
			addAtmospheric STOTZlist1
			STOTZContourlist=$CHAR_STOTZ_GEO_*_CON as array
			append TTBillboard.MasterArray STOTZContourlist
			STOTZlist2 = VrayToon name:"VRT_STOTZ_Contour" color:(color 255 255 255) excludeType:1 excludeList:STOTZContourList
			addAtmospheric STOTZlist2
		)

		if $CHAR_SPARKY_CNT_Root!=undefined do
		(
			SPARKYOutlineList=$CHAR_SPARKY_GEO_*_OUT as array
			append TTBillboard.MasterArray SPARKYOutlineList
			SPARKYlist1 = VrayToon name:"VRT_SPARKY_Outline" color:(color 255 255 255) hideInnerEdges:True excludeType:1 excludeList:SPARKYOutlineList
			addAtmospheric SPARKYlist1
			SPARKYContourList=$CHAR_SPARKY_GEO_*_CON as array
			append TTBillboard.MasterArray SPARKYContourList
			SPARKYlist2 = VrayToon name:"VRT_SPARKY_Contour" color:(color 255 255 255) excludeType:1 excludeList:SPARKYContourList
			addAtmospheric SPARKYlist2
		)
		
		if $CHAR_BLINKER_CNT_Root!=undefined do
		(
			BLINKEROutlineList=$CHAR_BLINKER_GEO_*_OUT as array
			append TTBillboard.MasterArray BLINKEROutlineList
			BLINKERlist1 = VrayToon name:"VRT_BLINKER_Outline" color:(color 255 255 255) hideInnerEdges:True excludeType:1 excludeList:BLINKEROutlineList
			addAtmospheric BLINKERlist1
			BLINKERContourList=$CHAR_BLINKER_GEO_*_CON as array
			append TTBillboard.MasterArray BLINKERContourList
			BLINKERlist2 = VrayToon name:"VRT_BLINKER_Contour" color:(color 255 255 255) excludeType:1 excludeList:BLINKERContourList
			addAtmospheric BLINKERlist2
		)
		
		if $CHAR_TORK_CNT_Root!=undefined do
		(
			TORKOutlineList=$CHAR_TORK_GEO_*_OUT as array
			append TTBillboard.MasterArray TORKOutlineList
			TORKlist1 = VrayToon name:"VRT_TORK_Outline" color:(color 255 255 255) hideInnerEdges:True excludeType:1 excludeList:TORKOutlineList
			addAtmospheric TORKlist1
			TORKContourList=$CHAR_TORK_GEO_*_CON as array
			append TTBillboard.MasterArray TORKContourList
			TORKlist2 = VrayToon name:"VRT_TORK_Contour" color:(color 255 255 255) excludeType:1 excludeList:TORKContourList
			addAtmospheric TORKlist2
		)
		
		if $CHAR_DUG_CNT_Root!=undefined do
		(
			DUGOutlineList=$CHAR_DUG_GEO_*_OUT as array
			append TTBillboard.MasterArray DUGOutlineList
			DUGlist1 = VrayToon name:"VRT_DUG_Outline" color:(color 255 255 255) hideInnerEdges:True excludeType:1 excludeList:DUGOutlineList
			addAtmospheric DUGlist1
			DUGContourList=$CHAR_DUG_GEO_*_CON as array
			append TTBillboard.MasterArray DUGContourList
			DUGlist2 = VrayToon name:"VRT_DUG_Contour" color:(color 255 255 255) excludeType:1 excludeList:DUGContourList
			addAtmospheric DUGlist2
		)
		
		if $CHAR_DIGBY_CNT_Root!=undefined do
		(
			DIGBYOutlineList=$CHAR_DIGBY_GEO_*_OUT as array
			append TTBillboard.MasterArray DIGBYOutlineList
			DIGBYlist1 = VrayToon name:"VRT_DIGBY_Outline" color:(color 255 255 255) hideInnerEdges:True excludeType:1 excludeList:DIGBYOutlineList
			addAtmospheric DIGBYlist1
			DIGBYContourList=$CHAR_DIGBY_GEO_*_CON as array
			append TTBillboard.MasterArray DIGBYContourList
			DIGBYlist2 = VrayToon name:"VRT_DIGBY_Contour" color:(color 255 255 255) excludeType:1 excludeList:DIGBYContourList
			addAtmospheric DIGBYlist2
		)
		
		if $CHAR_ZIPPY_CNT_Root!=undefined do
		(
			ZIPPYOutlineList=$CHAR_ZIPPY_GEO_*_OUT as array
			append TTBillboard.MasterArray ZIPPYOutlineList
			ZIPPYlist1 = VrayToon name:"VRT_ZIPPY_Outline" color:(color 255 255 255) hideInnerEdges:True excludeType:1 excludeList:ZIPPYOutlineList
			addAtmospheric ZIPPYlist1
			ZIPPYContourList=$CHAR_ZIPPY_GEO_*_CON as array
			append TTBillboard.MasterArray ZIPPYContourList
			ZIPPYlist2 = VrayToon name:"VRT_ZIPPY_Contour" color:(color 255 255 255) excludeType:1 excludeList:ZIPPYContourList
			addAtmospheric ZIPPYlist2
		)
		
		if $CHAR_TRENCHER_CNT_Root!=undefined do
		(
			TRENCHEROutlineList=$CHAR_TRENCHER_GEO_*_OUT as array
			append TTBillboard.MasterArray TRENCHEROutlineList
			TRENCHERlist1 = VrayToon name:"VRT_TRENCHER_Outline" color:(color 255 255 255) hideInnerEdges:True excludeType:1 excludeList:TRENCHEROutlineList
			addAtmospheric TRENCHERlist1
			TRENCHERContourList=$CHAR_TRENCHER_GEO_*_CON as array
			append TTBillboard.MasterArray TRENCHERContourList
			TRENCHERlist2 = VrayToon name:"VRT_TRENCHER_Contour" color:(color 255 255 255) excludeType:1 excludeList:TRENCHERContourList
			addAtmospheric TRENCHERlist2
		)
		
		for i =1 to TTBillboard.MasterArray.count do
		(
			for x=1 to TTBillboard.MasterArray[i].count do
			(
				if TTBillboard.MasterArray[i][x].ishidden==false do
				(
					append TTBillboard.hidegeo TTBillboard.MasterArray[i][x]
					hide TTBillboard.MasterArray[i][x]
				)
				
			)
		)
		
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
		fopenexr.setAutoAddRenderElements false		--Auto Add Render Elements
		reMgr = maxOps.GetCurRenderElementMgr ()
		ElCount=reMgr.NumRenderElements()
		fopenexr.delAllRenderElementLayers ()
		for i =1 to ElCount do
		(
			el = reMgr.getRenderElement (i-1)
			layername=el.elementname
			fopenexr.addrenderelementlayerref el layername 0 1
		)

	),	

	/*FnStart*******************************************************
	Function: Creates Render Elements
	*********************************************************FnEnd*/
	fn MakeRenderElementsFN =
	(
		TTBillboard.RenderSetupFN()
		
		reMgr = maxOps.getCurRenderElementMgr()
		elcount=reMgr.NumRenderElements()
		if elcount>0 then
		(
			ENVI=false
			CHAR=false
			for i =1 to elcount do
			(
				RendEl=reMgr.GetRenderElement (i-1)
				
				if RendEl.ElementName=="MultiMatteElement_ENVI" then
				(
					ENVI=true
				)
				if RendEl.ElementName=="MultiMatteElement_CHAR" then
				(
					CHAR=true
				)
			)
			
			if ENVI==false do
			(
				MMEENV=MultiMatteElement ElementName:"MultiMatteElement_ENVI" filterOn:false redListType:1 greenListType:1 blueListType:1 R_gbufIDOn:false G_gbufIDOn:false B_gbufIDOn:false affect_matte_objects:false
				reMgr.AddRenderElement MMEENV
			)
			
			if CHAR==false do
			(
				MMECHA=MultiMatteElement ElementName:"MultiMatteElement_CHAR" filterOn:false redListType:1 greenListType:1 blueListType:1 R_gbufIDOn:false G_gbufIDOn:false B_gbufIDOn:false affect_matte_objects:false
				reMgr.AddRenderElement MMECHA
			)
		)
		else
		(
			MMEENV=MultiMatteElement ElementName:"MultiMatteElement_ENVI" filterOn:false redListType:1 greenListType:1 blueListType:1 R_gbufIDOn:false G_gbufIDOn:false B_gbufIDOn:false affect_matte_objects:false
			reMgr.AddRenderElement MMEENV
			
			MMECHA=MultiMatteElement ElementName:"MultiMatteElement_CHAR" filterOn:false redListType:1 greenListType:1 blueListType:1 R_gbufIDOn:false G_gbufIDOn:false B_gbufIDOn:false affect_matte_objects:false
			reMgr.AddRenderElement MMECHA
		)	
		
		
		
	),
	
	/*FnStart*******************************************************
	Function: UI Function
	*********************************************************FnEnd*/
	fn UI =
	(
		rollout _TTBillboardR "TT Billboard Setup" width:130
		(
			local btWid=_TTBillboardR.width-15
			groupbox _LinesGbx pos:[8,2] width:btWid height:75
			button _LinesBt "Create Lines" width:(btWid-4) pos:[_LinesGbx.pos.x+2,_LinesGbx.pos.y+8]
			button _EnDlBt "Environment Dialog" width:(btWid-4) pos:[_LinesBt.pos.x,_LinesBt.pos.y+22]
			button _ShowLinesBt "Unhide Objects" width:(btWid-4) enabled:false pos:[_EnDlBt.pos.x,_EnDlBt.pos.y+22]
			
			timer _EnvClock interval:1 active:false
						
			on _LinesBt pressed do
			(
				if TTBillboard.MasterArray.count==0 then
				(
					TTBillboard.MakeOutlinesFN()
				)
				else
				(
					if queryBox "Do You Want to Erase all Line Settings?" beep:false then
					(
						TTBillboard.MakeOutlinesFN()
					)
				)
				
				if (envEffectsDialog.isOpen())==true then
				(
					envEffectsDialog.close()
					_EnvClock.active=true
				)
				else
				(
						TTBillboard.EnVOpenFN()
				)
				
				_ShowLinesBt.enabled=true
			)
			
			on _EnvClock tick do
			(
				_EnvClock.active=false
				TTBillboard.EnVOpenFN()
			)
			
			on _EnDlBt pressed do
			(
				if (envEffectsDialog.isOpen())==true then
				(
					envEffectsDialog.close()
					_EnvClock.active=true
				)
				else
				(
					TTBillboard.EnVOpenFN()
				)
			)
			
			on _ShowLinesBt pressed do
			(
				TTBillboard.showMasterArrayFN()
			)
						
			groupbox _RendElGbx pos:[_LinesGbx.pos.x,_LinesGbx.pos.y+_LinesGbx.height] width:_LinesGbx.width height:53
			button _RenBt "Set Up Renderer" width:(btWid-4) pos:[_RendElGbx.pos.x+2,_RendElGbx.pos.y+8]
			button _ElDlBt "Elements Dialog" width:(btWid-4) pos:[_RenBt.pos.x,_RenBt.pos.y+22]
			timer _RenElclock interval:1 active:false
						
			on _RenBt pressed do
			(
				TTBillboard.MakeRenderElementsFN()
				
				if (renderSceneDialog.isOpen())==false then
				(
					TTBillboard.RendElOpenFN()
	
				)
				else
				(
					tabbedDialogs.setCurrentPage #render #(1547006576, 1564889954)
				)

				
			)
			
			on _RenElclock tick do
			(
				_RenElclock.active=false
				TTBillboard.RendElOpenFN()
			)
			
			on _ElDlBt pressed do
			(
				if (renderSceneDialog.isOpen())==true then
				(
					renderSceneDialog.close()
					_RenElclock.active=true
				)
				else
				(
					TTBillboard.RendElOpenFN()
				)
			)
			
			groupbox _RenderGbx pos:[_RendElGbx.pos.x,_RendElGbx.pos.y+_RendElGbx.height] width:_LinesGbx.width height:53
			button _SnapBt "Snapshot" width:(btWid-4) pos:[_RenderGbx.pos.x+2,_RenderGbx.pos.y+8]
			button _RendoutBt "Render Sequence" width:(btWid-4) pos:[_SnapBt.pos.x,_SnapBt.pos.y+22]
				
			on _SnapBt pressed do
			(
				TTBillboard.FNExrSetup()
				TTBillboard.RenderSetupFN()
				TTBillboard.FNExrSetup()
				max quick render
			)
						
			on _RendoutBt pressed do
			(
				TTBillboard.FNExrSetup()
				TTBillboard.RenderSetupFN()
				TTBillboard.FNExrSetup()
				rendTimeType = 2
				rendSaveFile = true
				renderSceneDialog.update()
				if queryBox "Do You Want to submit to the Farm?" beep:false then
				(
					m = NetRender.GetManager() 
					m.connect #manual "licensing"
					_FrameStart = animationrange.start
					_FrameEnd = animationrange.end
					_Priority = 50
					_RenCam = "PhysCamera001"
					_suspended = false
					_JobType = "Billboard Render"
					_jobName = (getFilenameFile maxfilename) + "-[" + _JobType + "]"
					job = m.newjob()
					job.name = _jobName
					job.priority = _Priority
					job.suspended = _suspended
					job.FromFrame = _FrameStart
					job.ToFrame = _FrameEnd
					job.RenderCamera = _RenCam
					if queryBox "Is this Job Critical?" beep:false then
					(
						job.priority = 0
					)
					job.submit()

				)
				else
				(
					max quick render
				)
				rendTimeType = 1
				rendSaveFile = false
				renderSceneDialog.update()
			)
			
			on _TTBillboardR close do
			(
				TTBillboard._TTBillboardR=undefined
			)
		)
	),
	
	
	/*FnStart*******************************************************
	Function: Main Run Function
	*********************************************************FnEnd*/
	fn run =
	(
		if _TTBillboardR==undefined then
		(
			_TTBillboardR=UI()
			createDialog  _TTBillboardR style:#(#style_toolwindow,#style_sysmenu) width:130
		)
		else
		(
			destroyDialog   _TTBillboardR
			TTBillboard._TTBillboardR=undefined
		)	
	)
	
)
TTBillboard=TTBillboard()
TTBillboard.run()
