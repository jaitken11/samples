/*HeaderStart*******************************************************
Tool Name:		
Created By:	Josh Aitken
Company:	Keyframe Digital
E-Mail:		******
Start Date:	05/29/2019
Last Updated:	05/30/2019

Disclaimer:
This script has been tested to the best of the author's ability. Use at your own risk.
Any damage caused by this script is not the responsibility of the author.

Purpose:
	Reads chair data file given by VFX vendor to paste and sync onto Max asset for comp final match.

History:
	

To Do:
	

Bugs:
	

Notes:
	

Tested in:
	Max 2016 SP2

Tests:
	Razorback.run 825 415

*********************************************************HeaderEnd*/

try(destroyDialog Razorback._RazorbackR)catch()

/*Custom Att for Chair to bank data*/
RazorbackTrackcustAtt=attributes RazorbackTrackatt
(
	Parameters RazorbackTrackParam
	(
		trackdata Type:#stringTab tabSizeVariable:true
		STC Type:#string
		ETC Type:#string
		Framecount type:#integer
	)
)

struct Razorback
(
	_RazorbackR=undefined,
	_filepath=@"P:\17007_TheExpanseS3\_Working\_17007_WORK_Common\COM_TECH\COM_TECH_Razorback\12_DATA\MotionChair",
	_chairtarget=undefined,
	_FR=24,
	_data=undefined,
	_STC=undefined,
	_ETC=undefined,
	_Framecount=undefined,
	
	/*FnStart*******************************************************
	Function:	Main Tracking Function
	*********************************************************FnEnd*/
	fn animchair =
	(
		if Razorback._data == undefined do
		(
			Razorback._data = (dotnetClass "System.IO.File").ReadAllLines Razorback._filepath
		)			
		RingPoint=getnodebyname (Razorback._chairtarget+"_RingPt")
		ChairPoint=getnodebyname (Razorback._chairtarget+"_ChairPt")
		deleteKeys RingPoint.rotation.controller[2][2] #allKeys
		deleteKeys ChairPoint.rotation.controller[2][1] #allKeys
		framecount=Razorback._data[Razorback._data.count]
		Razorback._Framecount=((filterstring framecount " ")[1]) as integer
		
		CFR=frameRate
		
		if CFR != (Razorback._FR) then
		(
			msg="Scene Frame Rate is "+(CFR as string)+".\nFile Frame Rate should be 24.\nWould you like to change it and continue?"
			if querybox msg title:"Frame Rate Mismatch" then
			(
				frameRate=(Razorback._FR)
				Razorback.mapFN()
			)
			else
			(
				messagebox "Operation Aborted." title:"Notice"
			)
		)
		else
		(
			Razorback.mapFN()
		)
		if (isProperty RingPoint #trackdata) then
			(
				RingPoint.trackdata=Razorback._data
				RingPoint.STC=Razorback._STC
				RingPoint.ETC=Razorback._ETC
				RingPoint.Framecount=Razorback._Framecount
			)
			else
			(
				custAttributes.add RingPoint RazorbackTrackcustAtt
				RingPoint.trackdata=Razorback._data
				RingPoint.STC=Razorback._STC
				RingPoint.ETC=Razorback._ETC
				RingPoint.Framecount=Razorback._Framecount
			)
	),
	
	fn mapFN =
	(
		animationRange = interval 0 Razorback._Framecount
		TDStart="unknown"
		TDEnd="unknown"
		TDTag1=false
		TDTag2=false

		RingPoint=getnodebyname (Razorback._chairtarget+"_RingPt")
		ChairPoint=getnodebyname (Razorback._chairtarget+"_ChairPt")
		
		for i = 19 to Razorback._data.count do 
		(
			chairdata = (filterString Razorback._data[i] " ")
			slidertime=(chairdata[1] as integer)
			with animate on
			(
				RingPoint.rotation.controller[2][2].value= (-chairdata[3] as float)
				ChairPoint.rotation.controller[2][1].value= (-chairdata[2] as float)
			)
		
			if TDTag1==false do
			(
				chairdataPrev = (filterString Razorback._data[i-1] " ")
				if (chairdata[2] != chairdataPrev[2]) or (chairdata[3] != chairdataPrev[3]) do
				(
					TDStart=chairdata[1] as string
					TDTag1=true
				)
			)
			if TDTag1==true and TDTag2==false do
			(
				chairdataPrev = (filterString Razorback._data[i-1] " ")
				if (chairdata[2]==chairdataPrev[2]) or (chairdata[3]==chairdataPrev[3]) do
				(
					TDEnd=chairdataPrev[1] as string
					TDTag2=true
				)
			)
			
		)
		
		slidertime=animationrange.start
		Razorback._RazorbackR._TrimBox.enabled=true
		STC=(filterString Razorback._data[19] " ")
		Razorback._RazorbackR._StartTC.text=STC[STC.count] as string
		Razorback._STC=Razorback._RazorbackR._StartTC.text
		Razorback._RazorbackR._StartTC.enabled=true
		ETC=(filterString Razorback._data[Razorback._data.count] " ")
		Razorback._RazorbackR._EndTC.text=ETC[ETC.count] as string
		Razorback._ETC=Razorback._RazorbackR._EndTC.text
		Razorback._RazorbackR._EndTC.enabled=true
		Razorback._RazorbackR._TrimItBt.enabled=true

		/*Success message*/
	-- 			msg=Razorback._chairtarget+ " mapped.\nFramecount: "+ (framecount as string)+"\nTechno Dolly Start Frame: "+TDStart+"\nTechno Dolly End Frame: "+TDEnd
	-- 			
	-- 				messagebox msg title:"Success"
		clearlistener()
	-- 				print msg
	),
	
	/*FnStart*******************************************************
	Function:	Checks data to see when chair starts and stops
	moving and trims timeline to those points
	*********************************************************FnEnd*/
	fn AnimTrim =
	(
		sFrame=undefined
		eFrame=undefined
		for i=19 to Razorback._data.count do
		(
			TC=(filterString Razorback._data[i] " ")
			TC=TC[TC.count]
			if (TC as string)==Razorback._RazorbackR._StartTC.text do
			(
				sFrame=(filterString Razorback._data[i] " ")
				sFrame=sFrame[1] as integer
			)
			if (TC as string)==Razorback._RazorbackR._EndTC.text do
			(
				eFrame=(filterString Razorback._data[i] " ")
				eFrame=eFrame[1] as integer
			)
		)
		if sFrame != undefined and eFrame!=undefined then
		(
			if sFrame < eFrame then
			(
				animationRange = interval sFrame eFrame
				slidertime=animationrange.start
				Razorback._RazorbackR._ResetTrim.enabled=true
			)
			else
			(
				Razorback._RazorbackR._StartTC.text=Razorback._STC
				Razorback._RazorbackR._EndTC.text=Razorback._ETC
				messagebox "Start Frame after End Frame." title:"Error"
			)
		)
		else
		(
			Razorback._RazorbackR._StartTC.text=Razorback._STC
			Razorback._RazorbackR._EndTC.text=Razorback._ETC
			messagebox "Timecode not found." title:"Error"

		)
	),
	
	/*FnStart*******************************************************
	Function:	Main UI Function
	*********************************************************FnEnd*/
	fn UI =
	(
		rollout _RazorbackR "Razorback ChairTrack"
		(
			local btWid=_RazorbackR.width-15
			
			button _filepathBt "Get Tracking File" width:btWid pos:[7,7]
			button _ChairBt "Get Chair" width:btWid pos:[_filepathBt.pos.x,_filepathBt.pos.y+22]
			button _MapItBt "Map Chair" width:btWid pos:[_filepathBt.pos.x,_ChairBt.pos.y+22] enabled:false
			groupbox _TrimBox "Timecode Trim" width:btWid height:140 pos:[_filepathBt.pos.x,_MapItBt.pos.y+22] enabled:false
			edittext _StartTC "Start:" labelOnTop: true width:(btWid-10) pos:[_TrimBox.pos.x+5,_TrimBox.pos.y+15] enabled:false
			edittext _EndTC "End:" labelOnTop: true width:(btWid-10) pos:[_StartTC.pos.x,_StartTC.pos.y+20] enabled:false
			button _TrimItBt "Trim" width:(btWid-10) pos:[_StartTC.pos.x,_EndTC.pos.y+22] enabled:false
			button _ResetTrim "Reset" width:(btWid-10) pos:[_TrimItBt.pos.x,_TrimItBt.pos.y+22] enabled:false
				
			on _filepathBt pressed do
			(
				holdpath=Razorback._filepath
				try(Razorback._filepath = (getOpenFileName  caption:"Choose Save Directory" types:"Text(*.txt)|*.txt" initialDir:Razorback._filepath)
					
					Razorback._data=undefined
					_filepathBt.caption = "Data Set"
					print "Data Set."
					
				)
				catch()
				if Razorback._filepath == undefined then
				(
					Razorback._filepath=@"P:\17007_TheExpanseS3\_Working\_17007_WORK_Common\COM_TECH\COM_TECH_Razorback\12_DATA\MotionChair"
					_filepathBt.caption="Get Tracking"
				)
				if _filepathBt.caption!="Get Tracking" and Razorback._chairtarget !=undefined do
				(
					_MapItBt.enabled=true
				)
			)
			
			on _ChairBt pressed do
			(
				if selection[1]!=undefined then
				(
					basename=filterstring selection[1].name "_"
					if getnodebyname (basename[1]+"_ChairPt") !=undefined and getnodebyname (basename[1]+"_RingPt") !=undefined then
					(
						Razorback._chairtarget=basename[1]
						_ChairBt.caption=basename[1]
						print ("Selected Chair: "+_ChairBt.caption)
						RingPoint=getnodebyname (Razorback._chairtarget+"_RingPt")
						if (isProperty RingPoint #trackdata) do
						(
							if querybox "Previous Data Found.\nWould You like to load it?" title:"Query" do
							(
								Razorback._data=RingPoint.trackdata
								Razorback._STC=RingPoint.STC
								Razorback._ETC=RingPoint.ETC
								Razorback._Framecount=RingPoint.Framecount
								STC=(filterString Razorback._data[(animationrange.start.frame+19)] " ")
								_StartTC.text=STC[STC.count]
								STC=(filterString Razorback._data[animationrange.end.frame+19] " ")
								_EndTC.text=STC[STC.count]
								_filepathBt.caption = "Data Set"
								_TrimBox.enabled=true
								_StartTC.enabled=true
								_EndTC.enabled=true
								_TrimItBt.enabled=true
								_ResetTrim.enabled=true
							)
						)
					)
					else
					(
						messagebox "Chair references not detected" title:"Error"
					)
					if _filepathBt.caption!="Get Tracking" and Razorback._chairtarget !=undefined do
					(
						_MapItBt.enabled=true
					)
				)
				else
				(
					messagebox "Select a part of a chair" title:"Error"
				)
			)
			
			on _MapItBt pressed do
			(
				Razorback.animchair()
			)
			
			on _TrimItBt pressed do
			(
				Razorback.AnimTrim()
			)
			
			on _ResetTrim pressed do
			(
				Razorback._RazorbackR._StartTC.text=Razorback._STC
				Razorback._RazorbackR._EndTC.text=Razorback._ETC
				animationRange = interval 0 Razorback._Framecount
				slidertime=animationrange.start
			)
			
			on _RazorbackR close do
			(
				Razorback._RazorbackR=undefined
			)
		)
	),
	
	fn run =
	(
		if _RazorbackR==undefined then
		(
			_RazorbackR=UI()
			createDialog  _RazorbackR style:#(#style_toolwindow,#style_sysmenu) width:150
		)
		else
		(
			destroyDialog   _RazorbackR
			Razorback._RazorbackR=undefined
		)	
	)
	
)
Razorback=Razorback()
Razorback.run()
actionMan.executeAction 0 "40472"
clearlistener()
