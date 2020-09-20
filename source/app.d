import std.stdio;
import std.string;
import rconclient;



int main(string[] args)
{
	if(args.length < 4)
	{
		writefln("usage: %s <ip> <port> <pass>",args[0]);
		return 0;
	}


	auto rconClient = new RconClient();

	const auto success = rconClient.connect(args[1],args[2]);

	if(!success)
	{
		writefln("failed to connect to: %s:%s",args[1],args[2]);
		return 0;
	}
	
	const auto auth = rconClient.auth(args[3]);

	// is there a more idomatic way to do this?
	while(true) {

		writef("$ ");

		auto input = stdin.readln().strip();

		if(input == "quit" || input == "exit") {
			break;
		}

		else {
			const auto resp = rconClient.sendCommand(input);
			writefln("\n %s",resp);
		}
	}

	return 0;
}
