/*HeaderStart*******************************************************
Tool Name:	Texel Density Tool
Created By:	Josh Aitken
Company:	Apocalypse Studios
E-Mail:		******
Start Date:	03/31/2021
Last Updated:	04/05/2021

Disclaimer:
This script has been tested to the best of the author's ability. Use at your own risk.
Any damage caused by this script is not the responsibility of the author.

Purpose:
	Allows user to create uniform texel density across scene assets.

History:
	

To Do:
	

Bugs:
	

Notes:
	

Tested in:
	Max 2021 SP3

Tests:
	TexelDensity.run 500 500

*********************************************************HeaderEnd*/

try(destroyDialog TexelDensity._TexelDensityR)catch()

struct TexelDensity
(
	_TexelDensityR=undefined,
	_SysUniType=undefined,
	
	/*FnStart*******************************************************
	Function: Gets System Units
	*********************************************************FnEnd*/
	fn GetSysUni =
	(
		val = (units.systemType as string)
		val [1] = (toUpper val [1])
		TexelDensity._SysUniType = "System units = "+ val
	),
	
	/*FnStart*******************************************************
	Function: Function that scales selected UVs by a Multiplier
	around specific Pivot in a selected Direction
	e.g.: UVScaleByPivot 2 "UV" "TopLeft"
	*********************************************************FnEnd*/
	fn UVScaleByPivot ScaleMultiplier ScaleDirection PivotMode =
	(
		uvw_mod = modpanel.getcurrentobject()
			
		pm = case PivotMode of
		(
			"Center":1
			"Top":7
			"Bottom":3
			"Left":9
			"Right":5
				
			"TopLeft":8
			"Top-Left":8
			"LeftTop":8
			"Left-Top":8
			
			"TopRight":6
			"Top-Right":6
			"RightTop":6
			"Right-Top":6	
			
			"BottomLeft":2
			"Bottom-Left":2
			"LeftBottom":2
			"Left-Bottom":2
			
			"BottomRight":4
			"Bottom-Right":4
			"RightBottom":4
			"Right-Bottom":4
				
		)		
		
		sd = case ScaleDirection of
		(
			"U":point2 ScaleMultiplier 1 
			"V":point2 1 ScaleMultiplier
			"UV":point2 ScaleMultiplier ScaleMultiplier
		)
			
		uvw_mod.snapPivot pm 
		PivotPosition = (uvw_mod.getPivotOffset() + uvw_mod.getSelCenter())
		
		uvw_mod.scaleSelectedXY sd.x sd.y PivotPosition
	),
	
	
	/*FnStart*******************************************************
	Function: Calculates how many "meters" in system units
	*********************************************************FnEnd*/
	fn GetMetersFromGU =
	(
		meters = case units.systemType of
		(
			#Inches: 0.0254
			#Feet: 0.3048
			#Miles: 1609.0
			#Millimeters: 0.001
			#Centimeters: 0.01
			#Meters: 1.0
			#Kilometers: 1000.0
		)
		return meters*units.SystemScale
	),
	
	
	/*FnStart*******************************************************
	Function: Gets Texel Density
	*********************************************************FnEnd*/
	fn GetTexelDensity theMapSize =
	(
		if classof (unwrapmod = modpanel.getcurrentobject()) == unwrap_uvw do
		(
			if (faces = unwrapmod.getselectedfaces()).count > 0 do
			(
				unwrapmod.getarea faces &mX &mY &mWidth &mHeight &mAreaUVW &mAreaGeom
				textureArea = theMapSize^2
				usedAreaPixels = mAreaUVW * textureArea
				texelDensityVal = sqrt (usedAreaPixels/mAreaGeom)
			)
		)
		texelDensityVal
	),
	
	
	/*FnStart*******************************************************
	Function: Adds selected map onto asset
	*********************************************************FnEnd*/
	fn AddMap MapSize =
	(
		theMaterials = (for m in SceneMaterials collect m)
		TDMat=undefined
		
		for n in theMaterials do
		(
			if ((filterstring n.name "_")[1]) == "TDMatCheck" do
			(
				if ((filterstring n.name "_")[2]) == mapsize do
				(
					TDMat = n
				)
			)
		)
		if TDMat == undefined do
		(
			TDMat= (PhysicalMaterial name:("TDMatCheck_"+MapSize+"_Material") showinviewport:true)
			TexMap=(BitmapTexture name:("TDMatCheck_"+MapSize+"_Map") filename:(texToolPath + @"TexelDensity\textures\"+MapSize+".png"))
			TDMat.basecolormap=TexMap
		)
		
		for s in selection do
		(
			s.material=TDMat
		)
	),
	
	/*FnStart*******************************************************
	Function: Main UI
	*********************************************************FnEnd*/
	fn UI =
	(
		rollout _TexelDensityR "Texel Density"
		(
			local gpWid=_TexelDensityR.width-10
			local obj_ResolutionsArray = #(" 8192x8192", " 4096x4096", " 2048x2048", " 1024x1024", " 512x512")
			local UnwrapError = "Please select an object with Unwrap UVW modifier applied to it."
			local thePivotPosition = "Center"
		
			fn GetResolution ResolutionString = 
			(
				local theResolution = case ResolutionString of
				(
					" 8192x8192": 8192
					" 4096x4096": 4096
					" 2048x2048": 2048
					" 1024x1024": 1024
					" 512x512": 512
				)
				return theResolution
			)
			/*Header UI*/
			groupbox _TopGbx "Texel Density = (Px/m)" pos:[5,7] width:gpWid height:92
			edittext _SysUnitEt pos:[_TopGbx.pos.x+6,_TopGbx.pos.y+17] text:TexelDensity._SysUniType readOnly:true tooltip:"System Units"
			button _getTDBt "Get" pos:[_TopGbx.pos.x+7,_SysUnitEt.pos.y+20] width:45 height:25 tooltip: "Gets texel density from a selected UV-Shells \n(Unwrap UVW modifier should be applied)"
			spinner spnTexDens range:[0,8192,1024] pos:[_getTDBt.pos.x+50,_getTDBt.pos.y+5] width:55 type:#float tooltip: "Texel Density" scale: 128
			button _setTDBt "Set" pos:[spnTexDens.pos.x+17,_getTDBt.pos.y] width:45 height:25 tooltip: "Sets texel density to a selected UV-Shells \n(Unwrap UVW modifier should be applied)"
			label lblMSText "Map Size:" pos:[_getTDBt.pos.x+2,_getTDBt.pos.y+32] width:50 height:15
			dropdownlist drpdnMapSize items:obj_ResolutionsArray pos:[lblMSText.pos.x+48,lblMSText.pos.y-3] width:106 selection: 3 Tooltip: "Target Map Resolution"
			
			/*Scale UVs*/
			groupbox _ScaleGbx "Scale UVs:" pos:[_TopGbx.pos.x,_TopGbx.pos.y+_TopGbx.height+5] width:((gpWid/2)-5) height:200		
			spinner spn_Scale pos:[_ScaleGbx.pos.x+5,_ScaleGbx.pos.y+18] range:[0,100,2] width:70 height:25 type:#float scale: 0.01 tooltip: "Scale Factor"
			checkbutton _ScaleUCbt "U" checked:true tooltip:"Scale Horizontally" pos: [_ScaleGbx.pos.x+5,spn_Scale.pos.y+20] width:34 height:16
			checkbutton _ScaleVCbt "V" checked:true tooltip:"Scale Vertically" pos: [_ScaleUCbt.pos.x+_ScaleUCbt.width+3,_ScaleUCbt.pos.y] width:_ScaleUCbt.width height:16
			
			button btn_Scale "Scale" pos:[_ScaleGbx.pos.x+5,_ScaleUCbt.pos.y+18] width:(_ScaleGbx.width-9) tooltip: "Scales Selected UV-Shells by a value \n(Unwrap UVW modifier should be applied)"

			button btn_Half "1/2" pos:[btn_Scale.pos.x,btn_Scale.pos.y+26] width:34 tooltip: "Scales selected UV-Shells by half \n(Unwrap UVW modifier should be applied)"
			button btn_Double "2" pos:[btn_Half.pos.x+btn_Half.width+3,btn_Half.pos.y] width:btn_Half.width tooltip: "Doubles the scale of selected UV-Shells \n(Unwrap UVW modifier should be applied)"
			
			/*UV Scale Pivot*/
			local ckwid=20
			groupbox _PivotGbx "Pivot" pos:[_ScaleGbx.pos.x+5,btn_Half.pos.y+30] width:((ckwid+3)*3) height:(ckwid*4)
			checkbutton _PTLCbt "" checked:false tooltip:"Top Left" pos: [_PivotGbx.pos.x+4,_PivotGbx.pos.y+15] width:ckwid height:ckwid
			checkbutton _PTCbt "" checked:false tooltip:"Top" pos: [_PTLCbt.pos.x+ckwid,_PTLCbt.pos.y] width:ckwid  height:ckwid
			checkbutton _PTRCbt "" checked:false tooltip:"Top Right" pos: [_PTCbt.pos.x+ckwid,_PTLCbt.pos.y] width:ckwid height:ckwid
			checkbutton _PLCbt "" checked:false tooltip:"Left" pos:[_PTLCbt.pos.x,_PTLCbt.pos.y+ckwid] width:ckwid height:ckwid
			checkbutton _PCCbt "" checked:true tooltip:"Center" pos:[_PTCbt.pos.x,_PLCbt.pos.y] width:ckwid height:ckwid
			checkbutton _PRCbt "" checked:false tooltip:"Right" pos:[_PTRCbt.pos.x,_PLCbt.pos.y]width:ckwid height:ckwid
			checkbutton _PBLCbt "" checked:false tooltip:"Bottom Left" pos:[_PTLCbt.pos.x,_PLCbt.pos.y+ckwid] width:ckwid height:ckwid
			checkbutton _PBCbt "" checked:false tooltip:"Bottom" pos:[_PTCbt.pos.x,_PBLCbt.pos.y] width:ckwid height:ckwid
			checkbutton _PBRCbt "" checked:false tooltip:"Bottom Right" pos:[_PTRCbt.pos.x,_PBLCbt.pos.y] width:ckwid height:ckwid
			
			on spnTexDens changed val do theTexDen = val * (TexelDensity.GetMetersFromGU())

			fn UnpressButtons = 
			(
					_PTCbt.checked = false
					_PTRCbt.checked = false
					_PTLCbt.checked = false
					
					_PLCbt.checked = false
					_PCCbt.checked = false
					_PRCbt.checked = false
					
					_PBLCbt.checked = false
					_PBCbt.checked = false
					_PBRCbt.checked = false
			)
			
			fn PressCorrespondingBtn thePivotPosition =
			(
				UnpressButtons()
				case thePivotPosition of
				(
					
					"Center": _PCCbt.checked = true
					"Top": _PTCbt.checked = true
					"Bottom": _PBCbt.checked = true
					"Left": _PLCbt.checked = true
					"Right": _PRCbt.checked = true
					
					"TopLeft": _PTLCbt.checked = true
					"Top-Left": _PTLCbt.checked = true
					"LeftTop": _PTLCbt.checked = true
					"Left-Top": _PTLCbt.checked = true
				
					"TopRight": _PTRCbt.checked = true
					"Top-Right": _PTRCbt.checked = true
					"RightTop": _PTRCbt.checked = true
					"Right-Top": _PTRCbt.checked = true	
				
					"BottomLeft": _PBLCbt.checked = true
					"Bottom-Left": _PBLCbt.checked = true
					"LeftBottom": _PBLCbt.checked = true
					"Left-Bottom": _PBLCbt.checked = true
				
					"BottomRight": _PBRCbt.checked = true
					"Bottom-Right": _PBRCbt.checked = true
					"RightBottom": _PBRCbt.checked = true
					"Right-Bottom": _PBRCbt.checked = true
				)
			)
			
			/*Pivot Toggles*/
			on _PTLCbt changed theState do
			(			
				thePivotPosition = "Top-Left"
				PressCorrespondingBtn (thePivotPosition)
			)
			
			on _PTCbt changed theState do
			(			
				thePivotPosition = "Top"
				PressCorrespondingBtn (thePivotPosition)
			)
			
			on _PTRCbt changed theState do
			(
				thePivotPosition = "Top-Right"
				PressCorrespondingBtn (thePivotPosition)
			)
			
			on _PLCbt changed theState do
			(
				thePivotPosition = "Left"
				PressCorrespondingBtn (thePivotPosition)
			)
			
			on _PCCbt changed theState do
			(
				thePivotPosition = "Center"
				PressCorrespondingBtn (thePivotPosition)
			)
			
			on _PRCbt changed theState do
			(
				thePivotPosition = "Right"
				PressCorrespondingBtn (thePivotPosition)
			)
			
			on _PBLCbt changed theState do
			(
				thePivotPosition = "Bottom-Left"
				PressCorrespondingBtn (thePivotPosition)
			)
			
			on _PBCbt changed theState do
			(
				thePivotPosition = "Bottom"
				PressCorrespondingBtn (thePivotPosition)
			)
			
			on _PBRCbt changed theState do
			(
				thePivotPosition = "Bottom-Right"
				PressCorrespondingBtn (thePivotPosition)
			)

			on btn_Scale pressed do
			(
				if modpanel.getcurrentobject() != undefined and classof (modpanel.getcurrentobject()) == Unwrap_UVW then
				(		
					if _ScaleUCbt.checked and not _ScaleVCbt.checked then
					(
						TexelDensity.UVScaleByPivot spn_Scale.value "U" thePivotPosition
					)
					else if not _ScaleUCbt.checked and _ScaleVCbt.checked then
					(
						TexelDensity.UVScaleByPivot spn_Scale.value "V" thePivotPosition
					)
					else if _ScaleUCbt.checked and _ScaleVCbt.checked do
					(
						TexelDensity.UVScaleByPivot spn_Scale.value "UV" thePivotPosition	
					)		
				)
				else messagebox UnwrapError		
			)

			on btn_Half pressed do
			(
				if modpanel.getcurrentobject() != undefined and classof (modpanel.getcurrentobject()) == Unwrap_UVW then
				(
					if _ScaleUCbt.checked and not _ScaleVCbt.checked then
					(
						TexelDensity.UVScaleByPivot 0.5 "U" thePivotPosition
					)
					else if not _ScaleUCbt.checked and _ScaleVCbt.checked then
					(
						TexelDensity.UVScaleByPivot 0.5 "V" thePivotPosition
					)
					else if _ScaleUCbt.checked and _ScaleVCbt.checked do
					(
						TexelDensity.UVScaleByPivot 0.5 "UV" thePivotPosition	
					)		
				)
				else messagebox UnwrapError		
			)

			on btn_Double pressed do
			(
				if modpanel.getcurrentobject() != undefined and classof (modpanel.getcurrentobject()) == Unwrap_UVW then
				(
					if _ScaleUCbt.checked and not _ScaleVCbt.checked then
					(
						TexelDensity.UVScaleByPivot 2 "U" thePivotPosition
					)
					else if not _ScaleUCbt.checked and _ScaleVCbt.checked then
					(
						TexelDensity.UVScaleByPivot 2 "V" thePivotPosition
					)
					else if _ScaleUCbt.checked and _ScaleVCbt.checked do
					(
						TexelDensity.UVScaleByPivot 2 "UV" thePivotPosition	
					)		
				)
				else messagebox UnwrapError		
			)

			on _getTDBt pressed do
			(
				theMapSize = (GetResolution (drpdnMapSize.selected))	
					
				if modpanel.getcurrentobject() != undefined and classof (modpanel.getcurrentobject()) == Unwrap_UVW then
				(
					spnTexDens.value =  (TexelDensity.GetTexelDensity theMapSize)/(TexelDensity.GetMetersFromGU())				
					theTexDen = spnTexDens.value * (TexelDensity.GetMetersFromGU())
				)
				else messagebox UnwrapError		
			)

			on _setTDBt pressed do
			(
				theTexDen = spnTexDens.value * (TexelDensity.GetMetersFromGU())	
				theMapSize = (GetResolution (drpdnMapSize.selected))	
				undo "Set Texel Density" on
				(				
					if theTexDen >0 then
					(
						if modpanel.getcurrentobject() != undefined and classof (modpanel.getcurrentobject()) == Unwrap_UVW then
						(
							actionMan.executeAction 2077580866 "40207"

							texelDensityCluster = TexelDensity.GetTexelDensity theMapSize
							format "Texel Density Cluster: %\n" texelDensityCluster

							theDefinedRatio=(theTexDen/texelDensityCluster)
							theUnwrapmod = modpanel.getcurrentobject()
							theUnwrapmod.scaleSelectedCenter theDefinedRatio 0
						) else messagebox UnwrapError
					)
						else messagebox "Please set Texel Density correctly."
				)
			)
			
			groupbox _MapsGbx "Maps:" pos:[_ScaleGbx.pos.x+_ScaleGbx.Width+5,_ScaleGbx.pos.y] width:_ScaleGbx.width height:_ScaleGbx.height
			button _AddMapBt "Add Map(s)" width:(_MapsGbx.width-9) pos:[_MapsGbx.pos.x+5,_MapsGbx.pos.y+18]
			button _ClearMapBt "Clear Map(s)" width:(_MapsGbx.width-9) pos:[_AddMapBt.pos.x,_AddMapBt.pos.y+25]
			button _FlatColTogbt "Tog Flat Col" width:(_MapsGbx.width-9)  pos:[_AddMapBt.pos.x,_ClearMapBt.pos.y+25] tooltip:"Toggle Active Viewport between\nFlat Color and Default Shading."
						
			on _AddMapBt pressed do
			(
				theMapSize = ((GetResolution (drpdnMapSize.selected))as string)
				TexelDensity.AddMap theMapSize
			)
			
			on _ClearMapBt pressed do
			(
				for s in selection do
				(
					s.material=undefined
				)
			)
			
			on _FlatColTogbt pressed do
			(
				NNPRSettings = NitrousGraphicsManager.GetActiveViewportSetting()
				NNPRSettings.VisualStyleMode
				if NNPRSettings.VisualStyleMode == #ConsistentColors then
				(
					NNPRSettings.VisualStyleMode=#Realistic
				)
				else
				(
					NNPRSettings.VisualStyleMode=#ConsistentColors
				)
			)
			
			on _TexelDensityR close do
			(
				TexelDensity._TexelDensityR=undefined
			)
		)
	),
	
	fn run PosX PosY=
	(
		if _TexelDensityR==undefined then
		(
			_TexelDensityR=UI()
			TexelDensity.GetSysUni()
			createDialog  _TexelDensityR pos:[PosX,PosY] style:#(#style_toolwindow,#style_sysmenu) width:180
		)
		else
		(
			destroyDialog   _TexelDensityR
			TexelDensity._TexelDensityR=undefined
		)	
	)
	
)
TexelDensity=TexelDensity()
