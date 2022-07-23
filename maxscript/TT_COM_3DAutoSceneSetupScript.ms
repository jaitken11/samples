/*HeaderStart*******************************************************
Tool Name:	Terrific Trucks Setup Script
Created By:	Josh Aitken
Company:	Keyframe Digital
E-Mail:		******
Start Date:	4/01/2016
Last Updated:	07/06/2016

Disclaimer:
This script has been tested to the best of the author's ability. Use at your own risk.
Any damage caused by this script is not the responsibility of the author.

Purpose:
	Auto Setup script for shots. Layout Artist can drag/drop the syntheyes created MS file into the scene,
	then drag this script in and follow each stage to easily set each shot up.

History:
	04/05/2016: 	Added in Digby and Zippy - Josh Aitken
			Changed order of Characters in ScaleSetupFN - Josh Aitken
			Removed duplicate eyescaleloop from EyeSetupFN - Josh Aitken	

	04/21/2016: 	Set up visibility tracks in EyeSetupFN - Eric Harvey
			Set up buttons for geo visibility and hiding/unhiding the socket geo. - Eric Harvey
			Set hideByCategory.geometry=false on rollout closed. - Eric Harvey
					
	07/06/2016:	Added Step to create IFL and import backgroundImage Seq - Josh Aitken
					
To Do:
	

Bugs:
	

Notes:
	

Tested in:
	Max 2016 SP2

Tests:
	TerrificTrucks3DSetup=TerrificTrucks3DSetup()
	TerrificTrucks3DSetup.VPConfig()
	TerrificTrucks3DSetup.LayerSetupFN()
	TerrificTrucks3DSetup.ObjSetupFN()
	TerrificTrucks3DSetup.ScaleSetupFN()
	TerrificTrucks3DSetup.EyeSetupFN()
	TerrificTrucks3DSetup.AlignEyesFN()

*********************************************************HeaderEnd*/

struct TerrificTrucks3DSetup
(
	
	/*Variables Declared*/
	
	Camlayer=undefined,
	Lightlayer=undefined,
	Riglayer=undefined,
	TrackDatalayer=undefined,
	CharTracklayer=undefined,
	Markerlayer=undefined,
	Misclayer=undefined,
	Objlayer=undefined,
	TTscalelayer=undefined,
	worldnode=undefined,
	sceneobj=undefined,
	scenescaleval=undefined,
	alignarray=#(),
	alignscalebank=#(),
	bypass=false,
	
	RigDepot= @"P:\16006_TerrificTrucks\_MasterFiles\_16006_MAST_Common\MAST_COM_CGASSET\COM_MAST_CHAR",
	--Char order "Blinker" "Dug" "Sparky" "Stotz" "Tork" "Digby" "Hatch" "Hauler" "Red" "Sweepy" "Trencher" "Zippy"
	eyeScaleVals=#(24.4719,31.563,31.538,60.7873,71.7486,24.8026,86.3302,undefined,54.3348,62.5538,33.5514,24.4719),
	gotscale=false,
	dist=undefined,
	scalenum=undefined,
	
	/*FnStart*******************************************************
	Function: Viewport Config
	*********************************************************FnEnd*/
	fn VPConfigFN =
	(
		viewport.setlayout #layout_1
		select $Camera01
		viewport.setType #view_camera
		Screenmode = NitrousGraphicsManager.GetActiveViewportSetting()
		Screenmode.VisualStyleMode = #shaded
		if TerrificTrucks3DSetup.bypass==false do
		(
			mfp=maxfilepath
			mfp= filterstring mfp @"\"
			mfn=(getFilenameFile maxfilename as string)
			mfn= filterstring mfn @"_"
			platedir=mfp[1]+@"\"+mfp[2]+@"\"+mfp[3]+@"\"+mfp[4]+@"\"+mfp[5]+@"\"+mfp[6]+@"\"+@"05_PLATES\"+mfn[1]+"_"+mfn[2]+"_"+mfn[3]+"_"+mfn[4]+@"-Track\"
			iflName=mfn[1]+"_"+mfn[2]+"_"+mfn[3]+".ifl"
			theFiles = getFiles (platedir+ "*.PNG")
			theIfl = createFile (platedir + iflName)
			for f in theFiles do format "%\n" (filenameFromPath f) to:theIfl
			close theIfl
			backgroundImageFileName=(platedir + iflName)
		)
		
		viewport.DispBkgImage = true
		if keyboard.escPressed == false then
		(
			TerrificTrucks3DSetup.layersetupFN()
		)
	),
	
	/*FnStart*******************************************************
	Function: Sets up layers in Scene
	*********************************************************FnEnd*/
	fn LayerSetupFN =
	(
		if (LayerManager.getLayerFromName "Cameras")==undefined then
		(
			TerrificTrucks3DSetup.Camlayer=(LayerManager.newLayerFromName "Cameras")
		)
		else
		(
			TerrificTrucks3DSetup.Camlayer=(LayerManager.getLayerFromName "Cameras")
		)
		
		if (LayerManager.getLayerFromName "Lights")==undefined then
		(
			TerrificTrucks3DSetup.Lightlayer=(LayerManager.newLayerFromName "Lights")
		)
		else
		(
			TerrificTrucks3DSetup.Lightlayer=(LayerManager.getLayerFromName "Lights")
		)
		
		if (LayerManager.getLayerFromName "Rigs")==undefined then
		(
			TerrificTrucks3DSetup.Riglayer=(LayerManager.newLayerFromName "Rigs")
		)
		else
		(
			TerrificTrucks3DSetup.Riglayer=(LayerManager.getLayerFromName "Rigs")
		)

		if (LayerManager.getLayerFromName "Tracking_Data")==undefined then
		(
			TerrificTrucks3DSetup.TrackDatalayer=(LayerManager.newLayerFromName "Tracking_Data")
		)
		else
		(
			TerrificTrucks3DSetup.TrackDatalayer=(LayerManager.getLayerFromName "Tracking_Data")
		)

		if (LayerManager.getLayerFromName "Character_Eye_Trackers")==undefined then
		(
			TerrificTrucks3DSetup.CharTracklayer=(LayerManager.newLayerFromName "Character_Eye_Trackers")
		)
		else
		(
			TerrificTrucks3DSetup.CharTracklayer=(LayerManager.getLayerFromName "Character_Eye_Trackers")
		)
		TerrificTrucks3DSetup.CharTracklayer.setparent TerrificTrucks3DSetup.TrackDatalayer
		TerrificTrucks3DSetup.CharTracklayer.ishidden=false
		
		if (LayerManager.getLayerFromName "Tracking_Markers")==undefined then
		(
			TerrificTrucks3DSetup.Markerlayer=(LayerManager.newLayerFromName "Tracking_Markers")
		)
		else
		(
			TerrificTrucks3DSetup.Markerlayer=(LayerManager.getLayerFromName "Tracking_Markers")
		)
		TerrificTrucks3DSetup.Markerlayer.setparent TerrificTrucks3DSetup.TrackDatalayer
		TerrificTrucks3DSetup.Markerlayer.ishidden=true
		
		if (LayerManager.getLayerFromName "Misc")==undefined then
		(
			TerrificTrucks3DSetup.Misclayer=(LayerManager.newLayerFromName "Misc")
		)
		else
		(
			TerrificTrucks3DSetup.Misclayer=(LayerManager.getLayerFromName "Misc")
		)
		TerrificTrucks3DSetup.Misclayer.setparent TerrificTrucks3DSetup.TrackDatalayer
		TerrificTrucks3DSetup.Misclayer.ishidden=true
		
		if (LayerManager.getLayerFromName "Moving_Objects")==undefined then
		(
			TerrificTrucks3DSetup.Objlayer=(LayerManager.newLayerFromName "Moving_Objects")
		)
		else
		(
			TerrificTrucks3DSetup.Objlayer=(LayerManager.getLayerFromName "Moving_Objects")
		)
		TerrificTrucks3DSetup.Objlayer.setparent TerrificTrucks3DSetup.TrackDatalayer
		TerrificTrucks3DSetup.Objlayer.ishidden=true
		
		if (LayerManager.getLayerFromName "Scale_Assets")==undefined then
		(
			TerrificTrucks3DSetup.TTscalelayer=(LayerManager.newLayerFromName "Scale_Assets")
		)
		else
		(
			TerrificTrucks3DSetup.TTscalelayer=(LayerManager.getLayerFromName "Scale_Assets")
		)

		TerrificTrucks3DSetup.TTscalelayer.setparent TerrificTrucks3DSetup.TrackDatalayer
 		
		if keyboard.escPressed == false then
		(
			TerrificTrucks3DSetup.objSetupFN()
		)
	),

	/*FnStart*******************************************************
	Function: Object Setup
	*********************************************************FnEnd*/
	fn  ObjSetupFN =
	(
		for o in objects do
		(
			setTransformLockFlags o #all
			o.renderable=false
					
			if superclassof o==camera then
			(
				TerrificTrucks3DSetup.Camlayer.addNode o
				o.showTrajectory = off
			)
			else if classof o==box then
			(
				TerrificTrucks3DSetup.Objlayer.addNode o
				o.showTrajectory = off
			)
			else
			(
				TerrificTrucks3DSetup.Misclayer.addNode o
				o.showTrajectory = off
			)
		)
		
		TrackNodes=($Tracker* as array)
			
		for i =1 to TrackNodes.count do
		(
			TerrificTrucks3DSetup.Markerlayer.addNode TrackNodes[i]
			setTransformLockFlags TrackNodes[i] #all
			TrackNodes[i].renderable=false
			TrackNodes[i].showTrajectory = off
		)
		
		fn eyeloop Obj ChCL=
		(
			rEyeHolder=obj+"_R"
			rEyeHolder=getnodebyname rEyeHolder
			
			if rEyeHolder !=undefined do
			(
				rEyeHolder.wirecolor=ChCL
				TerrificTrucks3DSetup.CharTracklayer.addNode rEyeHolder
			)
			
			lEyeHolder=obj+"_L"
			lEyeHolder=getnodebyname lEyeHolder
			
			if lEyeHolder !=undefined do
			(
				lEyeHolder.wirecolor=ChCL
				TerrificTrucks3DSetup.CharTracklayer.addNode lEyeHolder
			)
		)
		
		eyeloop "Blinker" (color 228 153 184)
		eyeloop "Dug" (color 255 193 86)
		eyeloop "Sparky" (color 143 225 87)
		eyeloop "Stotz" (color 200 200 200)
		eyeloop "Tork" (color 222 62 62)
		eyeloop "Digby" (color 255 219 156)
		eyeloop "Hatch" (color 15 58 7)
		eyeloop "Hauler" (color 154 215 229)
		eyeloop "Red" (color 135 6 6)
		eyeloop "Sweepy" (color 255 255 255)
		eyeloop "Trencher" (color 255 89 7)
		eyeloop "Zippy" (color 225 87 143)
		
		TerrificTrucks3DSetup.SceneObj = $* as array
		
		TerrificTrucks3DSetup.WorldNode = dummy name:"WorldNode" renderable:false
		TerrificTrucks3DSetup.TTscalelayer.addNode TerrificTrucks3DSetup.WorldNode
		
		mergemaxfile (@"P:\16006_TerrificTrucks\_MasterFiles\_16006_MAST_Common\MAST_COM_Scripts\TT_COM_SceneSetupAssets\TT_COM_SceneSetupAssets_Scaleguy.max") #useSceneMtlDups
		bob=$Scaleguy
		TerrificTrucks3DSetup.TTscalelayer.addNode bob
		bob.renderable=false
		
		if keyboard.escPressed == false then
		(
			TerrificTrucks3DSetup.ScaleSetupFN()
		)
	),
	
	/*FnStart*******************************************************
	Function: Scale Setup
	*********************************************************FnEnd*/
	fn ScaleSetupFN =
	(
		fn eyescaleloop obj num=
		(
			if TerrificTrucks3DSetup.gotscale==false do
			(
				if TerrificTrucks3DSetup.eyeScaleVals[num]!=undefined do
				(
					rEyeHolder=obj+"_R"
					rEyeHolder=getnodebyname rEyeHolder
					lEyeHolder=obj+"_L"
					lEyeHolder=getnodebyname lEyeHolder
					if rEyeHolder!=undefined and lEyeHolder!=undefined do
					(
						print (obj +" is the scale reference")
						TerrificTrucks3DSetup.gotscale=true
						TerrificTrucks3DSetup.dist=distance rEyeHolder lEyeHolder
						TerrificTrucks3DSetup.scalenum=num
					)
				)
			)
		)
		
		eyescaleloop "Tork" 5
		eyescaleloop "Sparky" 3
		eyescaleloop "Dug" 2
		eyescaleloop "Stotz" 4
		eyescaleloop "Blinker" 1
		eyescaleloop "Digby" 6
		eyescaleloop "Hatch" 7
		eyescaleloop "Hauler" 8
		eyescaleloop "Red" 9
		eyescaleloop "Sweepy" 10
		eyescaleloop "Trencher" 11
		eyescaleloop "Zippy" 12
		
		if TerrificTrucks3DSetup.gotscale==true then
		(
			TerrificTrucks3DSetup.scenescaleval=(1/(TerrificTrucks3DSetup.dist/ TerrificTrucks3DSetup.eyeScaleVals[TerrificTrucks3DSetup.scalenum]))
			print ("Caculated Scene Scale = "+TerrificTrucks3DSetup.scenescaleval as string)
		)
		else
		(
			TerrificTrucks3DSetup.scenescaleval=1
			print ("No Scene Scale Available.")
		)
		rollout gui_SceneRescale "TT Scene Rescale"
		(
			spinner SScale "Scene Scale" type:#float range:[0.001, 100, TerrificTrucks3DSetup.scenescaleval]
			button RS "Rescale Scene"
			on RS pressed do
			(
				SceneScale = SScale.value
				for i = 1 to TerrificTrucks3DSetup.SceneOBJ.count do
				(
					if TerrificTrucks3DSetup.SceneOBJ[i].parent == undefined then (TerrificTrucks3DSetup.sceneobj[i].parent = TerrificTrucks3DSetup.worldNode)
				)
				TerrificTrucks3DSetup.WorldNode.scale = [SceneScale,SceneScale,SceneScale]
			)
			
			on gui_SceneRescale close do
			(
				SceneScale = SScale.value
				TerrificTrucks3DSetup.scenescaleval = SceneScale
				print ("Scene Scale = "+TerrificTrucks3DSetup.scenescaleval as string)
				TerrificTrucks3DSetup.Markerlayer.ishidden=true
				TerrificTrucks3DSetup.TTscalelayer.ishidden=true
				for i = 1 to TerrificTrucks3DSetup.SceneOBJ.count do
				(
					if (classof TerrificTrucks3DSetup.SceneOBJ[i]) == Freecamera do
					(
						TerrificTrucks3DSetup.SceneOBJ[i].target_distance /= SceneScale
					)
					if (classof TerrificTrucks3DSetup.SceneOBJ[i]) == VRayPhysicalCamera do
					(
						TerrificTrucks3DSetup.SceneOBJ[i].target_distance /= SceneScale
						TerrificTrucks3DSetup.SceneOBJ[i].f_number /= SceneScale
					)
				)
				TerrificTrucks3DSetup.EyeSetupFN()
			)
		)
		
		createdialog gui_sceneRescale style:#(#style_toolwindow,#style_sysmenu)
		
	),

	/*FnStart*******************************************************
	Function: Import Eyes and Scale them
	*********************************************************FnEnd*/
	fn EyeSetupFN =
	(
		fn eyemergeloop Pre Obj =
		(
			rEyeHolder=obj+"_R"
			rEyeHolder=getnodebyname rEyeHolder
			
			if rEyeHolder !=undefined do
			(
				mergemaxfile (TerrificTrucks3DSetup.RigDepot+@"\"+"TT_CHAR_"+Pre+obj+"_R_RG.max") #useSceneMtlDups
				rEyeAligner=("CHAR_"+obj+"_Align_R")
				rEyeAligner=getnodebyname rEyeAligner
				bankscale=rEyeAligner.scale
				rEyeAligner.transform=rEyeHolder.transform
				rEyeAligner.parent=rEyeHolder
				rEyeAligner.scale=bankscale
				print (obj+" Right Eye Merged.")
			)
			
			lEyeHolder=obj+"_L"
			lEyeHolder=getnodebyname lEyeHolder
			
			if lEyeHolder !=undefined do
			(
				mergemaxfile (TerrificTrucks3DSetup.RigDepot+@"\"+"TT_CHAR_"+Pre+obj+"_L_RG.max") #useSceneMtlDups
				lEyeAligner=("CHAR_"+obj+"_Align_L")
				lEyeAligner=getnodebyname lEyeAligner
				bankscale=lEyeAligner.scale
				lEyeAligner.transform=lEyeHolder.transform
				lEyeAligner.parent=lEyeHolder
				lEyeAligner.scale=bankscale--/TerrificTrucks3DSetup.scenescaleval)
				print (obj+" Left Eye Merged.")
			)
		)
		
		eyemergeloop "Hero_" "Blinker"
		eyemergeloop "Hero_""Dug"
		eyemergeloop "Hero_""Sparky"
		eyemergeloop "Hero_""Stotz"
		eyemergeloop "Hero_""Tork"
		eyemergeloop "" "Digby"
		eyemergeloop "" "Hatch"
		eyemergeloop "" "Hauler"
		eyemergeloop "" "Red"
		eyemergeloop "" "Sweepy"
		eyemergeloop "" "Trencher"
		eyemergeloop "" "Zippy"
		
		--Set up visibility controllers
		disableSceneRedraw() 
		for g in geometry do g.visibility = (linear_float())
		for g in geometry do g[1].controller = (linear_float())
		for g in geometry do g[1].controller.value = 1
		hideByCategory.geometry=true
		hideByCategory.geometry=false
		enableSceneRedraw() 
		
		
		if keyboard.escPressed == false then
		(
			TerrificTrucks3DSetup.AlignEyesFN()
		)
	),
	
	
	/*FnStart*******************************************************
	Function: Finish Aligning
	*********************************************************FnEnd*/
	fn AlignEyesFN =
	(
		TerrificTrucks3DSetup.alignarray=$*_Align* as array
			
		for i =1 to TerrificTrucks3DSetup.alignarray.count do
		(
			TerrificTrucks3DSetup.alignscalebank[i]=TerrificTrucks3DSetup.alignarray[i].scale
		)
		rollout gui_Align "TT Align" width:115
		(
			
			group "Eyes Geo"
			(
				button _ShowGeoBt "Show" width:50 align:#right across:2
				button _HideGeoBt "Hide" width:50 align:#left
				button _ShowSocketBt "Socket Show" width:50 align:#right across:2
				button _HideSocketBt "Socket Hide" width:50 align:#left
				button _OpaqueGeoBt "Opaque" width:50 align:#right across:2
				button _TransGeoBt "Transp." width:50 align:#left
				
				on _ShowGeoBt pressed do
				(
					hideByCategory.geometry=false
				)
				on _HideGeoBt pressed do
				(
					hideByCategory.geometry=true
				)
				
				on _ShowSocketBt pressed do
				(
					hideByCategory.geometry=false
					unhide $*socket*
				)
				on _HideSocketBt pressed do
				(
					hide $*socket*
				)
				
				on _OpaqueGeoBt pressed do
				(
					for g in geometry do 
					(
						if classof g != box or classof g != plane do
						(
							g.visibility.controller.value = 1
						)
					)
					hideByCategory.geometry=true
					hideByCategory.geometry=false
				)
				on _TransGeoBt pressed do
				(
					for g in geometry do 
					(
						if classof g != box do
						(
							g.visibility.controller.value = 0.1
						)
					)
					hideByCategory.geometry=true
					hideByCategory.geometry=false
				)
				
				
			)
			group "Helpers"
			(
				button _ShowHelpBt "Show" width:50 align:#right across:2
				button _HideHelpBt "Hide" width:50 align:#left
				
				on _ShowHelpBt pressed do
				(
					hideByCategory.helpers=false
				)
				on _HideHelpBt pressed do
				(
					hideByCategory.helpers=true
				)
			)
			group "FFDs"
			(
				button _ShowFFDBt "On" width:50 align:#right across:2
				button _HideFFDBt "Off" width:50 align:#left
				
				on _ShowFFDBt pressed do
				(
					FFDArr= $*lid_top as array
					for i=1 to FFDArr.count do
					(
						FFDArr[i].modifiers[1].enabled=true
					)
				)
				on _HideFFDBt pressed do
				(
					FFDArr= $*lid_top as array
					for i=1 to FFDArr.count do
					(
						FFDArr[i].modifiers[1].enabled=false
					)
				)
				
			)
			
			spinner _ScaleSp "Scale Val:" range:[0.001,100,1] type:#float align:#right
			
			on _ScaleSp changed arg do
			(
				for i =1 to TerrificTrucks3DSetup.alignarray.count do
				(
					TerrificTrucks3DSetup.alignarray[i].scale=(TerrificTrucks3DSetup.alignscalebank[i]*_ScaleSp.value)
				)
			)
			button _UpdateBt "Update Scale" width:100 align:#center
						
			on _UpdateBt pressed do
			(
				for i =1 to TerrificTrucks3DSetup.alignarray.count do
				(
					TerrificTrucks3DSetup.alignscalebank[i]=TerrificTrucks3DSetup.alignarray[i].scale
				)
				_ScaleSp.value=1.0
			)
			
			button _ResetBt "Reset Scale" width:100 align:#center
			
			on _ResetBt pressed do
			(
				_ScaleSp.value=1.0
				
				for i =1 to TerrificTrucks3DSetup.alignarray.count do
				(
					TerrificTrucks3DSetup.alignarray[i].scale=TerrificTrucks3DSetup.alignscalebank[i]
				)
				
			)
			
			on gui_Align close do
			(
				hideByCategory.geometry=false
				TerrificTrucks3DSetup.CharTracklayer.ishidden=true
				FFDArr= $*lid_top as array
				for i=1 to FFDArr.count do
				(
					FFDArr[i].modifiers[1].enabled=false
				)
				rootcnt=$*_Root as array
				for r in rootcnt do
				(
					setTransformLockFlags r #all
				)
				Clearselection()
				for g in geometry do
				(
					try(g.visibility.controller.value = 1)catch()
					if classof g != box and classof g != Plane do
					(
						deleteKeys g #allKeys
					)
				)
				macros.run "Scene Explorer" "SELayerExplorer"
				messagebox "Scene File Setup Complete" title:"Success"
			)
		)
		FFDArr= $*lid_top as array
		for i=1 to FFDArr.count do
		(
			FFDArr[i].modifiers[1].enabled=false
		)
		createdialog gui_Align style:#(#style_toolwindow,#style_sysmenu)
	),
	
	/*FnStart*******************************************************
	Function: Main Function Launcher
	*********************************************************FnEnd*/
	fn run =
	(
		if maxfilepath=="" then
		(
			if querybox "You must save your file first to create Background Sequence.\nDo you wish to Bypass?" title:"Notice" do
			(
				TerrificTrucks3DSetup.bypass=true
				if $Camera01!=undefined then
				(
					TerrificTrucks3DSetup.VPConfigFN()
				)
				else
				(
					messagebox "You need to import your tracking data first." Title:"Duh"
				)
			)
		)
		else
		(
			if $Camera01!=undefined then
			(
				TerrificTrucks3DSetup.VPConfigFN()
			)
			else
			(
				messagebox "You need to import your tracking data first." Title:"Duh"
			)
		)
	)
	

)
Clearselection()
TerrificTrucks3DSetup=TerrificTrucks3DSetup()
TerrificTrucks3DSetup.run()
