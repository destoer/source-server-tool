import std.stdio;
import std.string;
import rconclient;


import dlangui;
import dlangui.widgets.widget;
mixin APP_ENTRY_POINT;

RconClient rcon_client;

void execute_command(dstring command, Widget terminal) {
	if(!rcon_client.authed)
	{
		terminal.text = "not authenticted";
		return;
	}

	terminal.text = to!dstring(rcon_client.sendCommand(to!string(command)));
}

void auth(string ip, string port, string pass, Widget terminal) {

	try 
	{

		auto success = rcon_client.connect(ip,port);

		if(!success)
		{
			terminal.text = to!dstring(format("failed to connect to: %s:%s",ip,port));
			return;
		}

		success = rcon_client.auth(pass);

		if(!success)
		{
			terminal.text = to!dstring(format("failed to auth to: %s:%s:%s",ip,port,pass));
		}	

	}

	catch(Throwable)
	{
		terminal.text = "error connecting";
		return;
	}

	terminal.text = "authenticated";
}

Widget setup_window() {

	// setup the command input
	auto command_layout = new HorizontalLayout();
	command_layout.fillHorizontal();

	auto command_button = new Button(null,"Go!"d);

	auto command_input = new EditLine("#command",""d);
	command_input.fillHorizontal();

	command_layout.addChild(command_input);
	command_layout.addChild(command_button);

	// Setup the "terminal" window (yes a read only edit box is a lazy way to do this)
	auto terminal = new EditBox(null,"$"d);
	terminal.fillVertical();
	terminal.layoutWidth = WRAP_CONTENT;
	terminal.readOnly = true;

	auto cred_layout = new HorizontalLayout();
	cred_layout.fillHorizontal();
	auto ip_input = new EditLine("#ip",""d); ip_input.fillHorizontal();
	auto port_input = new EditLine("#port",""d); port_input.fillHorizontal();
	auto pass_input = new EditLine("#pass",""d); pass_input.fillHorizontal();
	auto cred_button = new Button(null,"login"d);

	cred_layout.addChild(new TextWidget(null,"ip: "d));
	cred_layout.addChild(ip_input);
	cred_layout.addChild(new TextWidget(null,"port: "d));
	cred_layout.addChild(port_input);
	cred_layout.addChild(new TextWidget(null,"pass: "d));
	cred_layout.addChild(pass_input);
	cred_layout.addChild(cred_button);
	



	auto vlayout = new VerticalLayout();
	vlayout.fillHorizontal();
	vlayout.fillVertical();


	vlayout.addChild(cred_layout);
	vlayout.addChild(terminal);
	vlayout.addChild(command_layout);
	

	command_button.click = delegate(Widget src) {
		execute_command(command_input.text,terminal);
		command_input.text = "";
		return true;
	};

	command_input.keyEvent = delegate(Widget widget, KeyEvent event) {

		// perform command on enter
		if(event.keyCode == KeyCode.RETURN && event.action == KeyAction.KeyDown)
		{
			execute_command(command_input.text,terminal);
			command_input.text = "";			
			return true;
		}

		else
		{
			return false;
		}
	};

	cred_button.click = delegate(Widget src) {
		auth(to!string(ip_input.text),to!string(port_input.text),to!string(pass_input.text),terminal);
		return true;
	};

	return vlayout;
}

extern (C) int UIAppMain(string[] args) {

	rcon_client = new RconClient(); 

	Window window = Platform.instance.createWindow("NewEraRcon",null);

	window.mainWidget = setup_window();

	window.show();
	return Platform.instance.enterMessageLoop();
}


// old command line UI

/*
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

	if(!auth)
	{
		writefln("failed to auth");
		return 0;
	}

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
*/