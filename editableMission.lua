quest playerMission begin
	state start begin
		function returnData()
			local data = {
				["missionData"] = {["missionName"] = "Player Mission I", ["missionFlag"] = "playerMissionKill"},
				
				["timeToComplete"] = {true, time_min_to_sec(60)},
				["requireData"] = {{691, 5}, {8001, 5}},
				
				["playerRewards"] = {["itemVnum"] = {19, 30006, 40}, ["itemCount"] = {1, 5, 1}}
			};
			
			return data;
		end
		
		function initializeData()
			local data = playerMission.returnData();
			
			for index in data["requireData"] do
				local strFlag = string.format("%s_%d", data["missionData"]["missionFlag"], data["requireData"][index][1]);
				pc.setqf(strFlag, data["requireData"][index][2]);
			end
			
			if (data["timeToComplete"][1]) then
				return pc.setqf("playerMissionTime", get_time() + data["timeToComplete"][2]);
			end return true;
		end
		
		function initializeInfo()
			local data = playerMission.returnData();
			for index in data["requireData"] do
				local strFlag = string.format("%s_%d", data["missionData"]["missionFlag"], data["requireData"][index][1]);
				q.set_counter(string.format("Remaining %s:", mob_name(data["requireData"][index][2])), pc.getqf(strFlag));
			end
			
			if (data["timeToComplete"][1]) then
				if (pc.getqf("playerMissionTime") < get_time()) then
					return false;
				end
				q.set_clock("Remaining Time:", pc.getqf("playerMissionTime") - get_time());
			end
			
			return true;
		end
		
		function isKillableMonster()
			local data = playerMission.returnData();
			local npcRace = npc.get_race();
			
			for index in data["requireData"] do
				if (data["requireData"][index][1] == npcRace) then
					return true;
				end
			end return false;
		end
		
		when login or enter or levelup begin
			local data = playerMission.returnData();
			send_letter(data["missionData"]["missionName"]);
		end
		
		when button or info begin
			local data = playerMission.returnData();
			
			say_title(string.format("%s:[ENTER]", data["missionData"]["missionName"]))
			say("Talk to Blacksmith if you want to accept the mission.")
		end
		
		when 20016.chat."The Player Mission" begin
			say_title(string.format("%s:[ENTER]", mob_name(npc.get_race())))
			say("Do you wish to accept the mission?")
			if (select("Yes, i do", "No, i don't") == 1) then
				playerMission.initializeData();
				set_state("run");
				say("Your mission has been updated.")
			end
		end
	end
	
	state run begin
		when login or enter begin
			local data = playerMission.returnData();
			local initializeMissionInfo = playerMission.initializeInfo();
			
			if (not initializeMissionInfo) then
				syschat(string.format("You failed mission: %s.", data["missionData"]["missionName"]))
				set_state("done");
				return;
			end
			
			send_letter(data["missionData"]["missionName"]);
		end
		
		when button or info begin
			local data = playerMission.returnData();
			
			say_title(data["missionData"]["missionName"])
			if (data["timeToComplete"][1]) then
				if (pc.getqf("playerMissionTime") < get_time()) then
					syschat(string.format("You failed mission: %s.", data["missionData"]["missionName"]))
					set_state("done");
					return;
				end
			end
			
			say("You still must kill:[ENTER]")
			for index in data["requireData"] do
				local strFlag = string.format("%s_%d", data["missionData"]["missionFlag"], data["requireData"][index][1]);
				if (pc.getqf(strFlag) > 0) then
					say_reward(string.format("- %s - x%d", mob_name(data["requireData"][index][1]), pc.getqf(strFlag)))
				end
			end
		end
		
		when kill with playerMission.isKillableMonster() begin
			local data = playerMission.returnData();
			local npcRace = npc.get_race();
			local isMissionOver = true;
			
			if (data["timeToComplete"][1]) then
				if (pc.getqf("playerMissionTime") < get_time()) then
					syschat(string.format("You failed mission: %s.", data["missionData"]["missionName"]))
					set_state("done");
					return;
				end
			end
			
			local npcFlag = string.format("%s_%d", data["missionData"]["missionFlag"], npcRace);
			if (pc.getqf(npcFlag) < 1) then
				return;
			end
			
			pc.setqf(npcFlag, pc.getqf(npcFlag) - 1);
			for index in data["requireData"] do
				local strFlag = string.format("%s_%d", data["missionData"]["missionFlag"], data["requireData"][index][1]);
				
				if (pc.getqf(strFlag) > 0) then
					isMissionOver = false;
				end
			end
			
			if (isMissionOver) then
				set_state("reward");
			end
		end
	end
	
	state reward begin
		when login or enter begin
			send_letter("*Player Mission Reward");
		end
		
		when button or info begin
			local data = playerMission.returnData();
			
			say_title("*Player Mission Reward")
			say("Go back to Blacksmith to take your reward.")
		end
		
		when 20016.chat."Your reward!" begin
			local data = playerMission.returnData();
			
			say_title(string.format("%s:[ENTER]", mob_name(npc.get_race())))
			say("You have succesfully completed the mission.[ENTER]Your reward is:")
			
			for index in data["playerRewards"]["itemVnum"] do
				pc.give_item2(data["playerRewards"]["itemVnum"][index], data["playerRewards"]["itemCount"][index]);
				say_reward(string.format("- %s - %d", item_name(data["playerRewards"]["itemVnum"][index]), data["playerRewards"]["itemCount"][index]))
			end
			
			set_state("done");
		end
	end
	
	state done begin
		when login or enter begin
			clear_letter();
			q.done();
		end
	end
end
