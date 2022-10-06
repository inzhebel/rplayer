{

      ____  _                       
 _ __|  _ \| | __ _ _   _  ___ _ __ 
| '__| |_) | |/ _` | | | |/ _ \ '__|
| |  |  __/| | (_| | |_| |  __/ |   
|_|  |_|   |_|\__,_|\__, |\___|_| v.1.3   
by inz.hebel        |___/           


Easy to use Internet radio player for headless devices 
with text-to-speech user interface

requires mpd, mpc, espeak-ng


}
program rplayer;

uses crt, sysutils, Unix, INIFiles, Classes, strutils;


var
	StationList : TStringList;
	Stations	: Array[1..999, 1..2] of string;
	exitlog		: ansistring;
	
	command		: string;
	key 		: char;
	channelstr 	: string[3];
	channel 	: integer;
	shellresult	: longint;
	isdebug		: boolean;
	voice		: byte;

    //////////////////////////////////////////////////////////////////
   //															   //
  //					  P R O C E D U R E S					  //
 //																 //
//////////////////////////////////////////////////////////////////


function switch(inputValue : boolean) : boolean;
begin 
	if inputValue = true then switch := false else switch := true;
	
end;


procedure banner;
	begin
		writeln('      ____  _                          ');
		writeln(' _ __|  _ \| | __ _ _   _  ___ _ __    ');
		writeln('| ''__| |_) | |/ _` | | | |/ _ \ ''__| ');
		writeln('| |  |  __/| | (_| | |_| |  __/ |      ');
		writeln('|_|  |_|   |_|\__,_|\__, |\___|_| v.1.2,1'); 
		writeln('by inz.hebel        |___/              ');
		writeln;                                       
	end;





function isPlaylist(var url : string) : boolean;
	begin
		isPlaylist := false;
		if AnsiContainsStr(url,'.m3u') then isPlaylist := true;
		if AnsiContainsStr(url,'.pls') then isPlaylist := true;
		if AnsiContainsStr(url,'.asx') then isPlaylist := true;
		
	end;
	
procedure say(texttosay :string);
	var scmd : string;
		srsult : longint;
	
	begin
		writeln(texttosay);

		if voice > 0 then
		begin

			scmd := 'espeak-ng -v polish "' + texttosay + '"';
			if voice = 2 then scmd := 'espeak -v mb-pl1 "' + texttosay + '"';
			// slitaz walkaround
			if fileexists('slitaz') then scmd := 'espeak -v polish "' + texttosay + '" --stdout | aplay -f S16_LE -c1 -r22000';
			
			srsult := fpSystem(scmd);
		end;
	end;

procedure update;
var fpresult : longint;
	cmd : string;
begin

	say('aktualizacja');
	cmd := 'update.sh';
	fpresult := fpSystem(cmd);
	writeln(fpresult);
end;

procedure LoadList;
	var
		i: Integer;
		SN: integer;
		Line: TstringList;

	begin

		StationList := TStringList.Create;
		StationList.LoadFromFile('stations.list');
		Line := TstringList.create;	
		for i := 0 to StationList.count -1 do
			begin
				Line.delimiter := ',';
				Line.StrictDelimiter := false;
				Line.Commatext := StationList.strings[i];
				SN := strtoint(line.strings[0]);	
				
				if isdebug then
				begin
				writeln(line.strings[0]);
				writeln(line.strings[1]);
				writeln(line.strings[2]);
				end;	

				if (SN > 0) and (SN < 999) then
					begin
						stations[SN,1] := line.strings[1];
						stations[SN,2] := line.strings[2];
					end;
		
			end;
		StationList.free;
		Line.free;
		say('lista załadowana');
	end;


procedure ChangeVoice;
begin
	if voice < 2 then voice:= voice +1 else voice := 0;
	say('Głos '+ IntToStr(voice));
end;



procedure ChannelChange(stnum : integer);

	begin
		channelstr := '';
		channel := stnum;
		if stnum = 0 then exit;
		shellresult := fpSystem('mpc -q clear');
		ClrScr;
		writeln(IntToStr(stnum));

		if stations[stnum,2] <> '' then
			begin
	//debug 			
			say(stations[stnum,1]);
			if isdebug then writeln(stations[stnum,2]);
			
					
			if isPlaylist(stations[stnum,2]) then
			command := 'mpc -q load ' + stations[stnum,2] else
			command := 'mpc -q add ' + stations[stnum,2];
			if isDebug then command := command + ' &' else 
//			command := command + ' < /dev/null > /dev/null 2>&1 &';
			
			if isdebug then writeln(command);
			
			shellresult := fpSystem(command);
					
			shellresult := fpSystem('mpc -q play');
			
			end
			else
			say('Nie ma takiego numeru');
	end;
	
procedure PrintStationsList;
	var
		x : integer;
	begin
		for x := 1 to 999 do if stations[x,2] <> '' then writeln(inttostr(x) + ' -- ' + stations[x,1] + '   ==> ' + stations[x,2]);		
	end;

procedure SetChannel(InputKey: char);
	begin
		if length(channelstr) = 3 then channelstr := '';
		channelstr := channelstr + InputKey;
		clrscr;
		writeln(channelstr);
	end;

procedure ChannelUp;
	begin
		repeat
			if channel = 999 then channel := 0;
			channel := channel + 1;			
		until Stations[channel,2] <> '';
		ChannelChange(channel); 
	end;


procedure ChannelDown;

	begin
		repeat
			if channel = 0 then channel := 1000;
			channel := channel - 1;
		until Stations[channel,2] <> ''; 
		ChannelChange(channel);
	end;

    /////////////////////////////////////////////////////////////////
   //															  //
  //					M A I N   L O O P						 // 
 //																//
/////////////////////////////////////////////////////////////////

begin

	voice := 1;
	isdebug := false;
	channel := 0;


	clrscr;
	banner;
	say('Radio Player');
	loadlist;

	repeat 
		key := readkey;
		case key of
			'+' 	 : ChannelUp;
			'-' 	 : ChannelDown;
			'0'..'9' : SetChannel(key);
			#13 	 : if channelstr <> '' then ChannelChange(strtoint(channelstr));
			'l'		 : PrintStationsList;
			'r'		 : LoadList;
			'd'		 : isdebug := Switch(isdebug);
			'v'		 : ChangeVoice;
			'/'		 : update;
		end;

	until key = 'q';
	shellresult := fpSystem('mpc -q clear');
	clrscr;
	

end.
