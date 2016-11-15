private ["_item","_type","_hasHarvested","_config","_knifeArray","_PlayerNear","_isListed","_activeKnife","_text","_dis","_sfx","_sharpnessRemaining","_qty","_chance","_msg","_string"];

_item = _this;
_type = typeOf _item;
_hasHarvested = _item getVariable["meatHarvested",false];
_config = configFile >> "CfgSurvival" >> "Meat" >> _type;

_knifeArray = [];

player removeAction s_player_butcher;
s_player_butcher = -1;

_PlayerNear = {isPlayer _x} count ((getPosATL _item) nearEntities ["CAManBase", 10]) > 1;
if (_PlayerNear) exitWith {cutText [localize "str_pickup_limit_5", "PLAIN DOWN"]};

//Count how many active tools the player has
{
	if (_x IN items player) then {
		_knifeArray set [count _knifeArray, _x];
	};
} count Dayz_Gutting;

if ((count _knifeArray) < 1) exitwith { cutText [localize "str_cannotgut", "PLAIN DOWN"] };


if ((count _knifeArray > 0) and !_hasHarvested) then {
	private "_qty";
	
	//Select random can from array
	_activeKnife = _knifeArray call BIS_fnc_selectRandom; 
	
	//Get Animal Type
	_isListed = isClass _config;
	_text = getText (configFile >> "CfgVehicles" >> _type >> "displayName");

	player playActionNow "Medic";
	_dis=10;
	_sfx = "gut";
	[player,_sfx,0,false,_dis] call dayz_zombieSpeak;
	[player,_dis,true,(getPosATL player)] call player_alertZombies;

	// Added Nutrition-Factor for work
	["Working",0,[20,40,15,0]] call dayz_NutritionSystem;

	_item setVariable ["meatHarvested",true,true];

	_qty = if (_isListed) then {getNumber (_config >> "yield")} else {2};
	if (_activeKnife == "ItemKnifeBlunt") then { _qty = round(_qty / 2); };

	if (local _item) then {
		[_item,_qty] spawn local_gutObject; //leave as spawn (sleeping in loops will work but can freeze the script)
	} else {		
		PVCDZ_obj_GutBody =[_item,_qty];
		publicVariable "PVCDZ_obj_GutBody";
		
		//achievement system
		if (!achievement_Gut) then {
			achievement_Gut = true;
		};
	};
	
	_sharpnessRemaining = getText (configFile >> "cfgWeapons" >> _activeKnife >> "sharpnessRemaining");
	
	switch _activeKnife do {
		case "ItemKnife" : { 
			//_chance = getNumber (configFile >> "cfgWeapons" >> _activeKnife >> "chance");
			if ([0.2] call fn_chance) then {
				player removeWeapon _activeKnife;
				player addWeapon _sharpnessRemaining;
				
				//systemChat (localize "str_info_bluntknife");	
				_msg = localize "str_info_bluntknife";
				_msg call dayz_rollingMessages;
			};	
		};
		case "ItemKnifeBlunt" : { 
			//do nothing
		};
		default { 
			player removeWeapon _activeKnife;
			player addWeapon _sharpnessRemaining;
		};
	};
	
	uiSleep 6;
	_string = format[localize "str_success_gutted_animal",_text,_qty];
	closeDialog 0;
	uiSleep 0.02;
	//cutText [_string, "PLAIN DOWN"];
	_string call dayz_rollingMessages;
};