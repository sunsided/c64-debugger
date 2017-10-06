C64 Debugger by SLAJEREK/SAMAR
------------------------------

C64 Debugger (C) 2016-2017 Marcin Skoczylas
Vice (C) 1993-2016 The VICE Team


This is Commodore 64 code and memory debugger that works in real time.
It is quick prototyping tool where you can play with Commodore 64 machine
and its internals.

C64 Debugger embeds VICE v3.1 C64 emulation engine created by The VICE Team.


** Note to C64 Debugger source files **

So, you would like to step into this entertainment coding mystery of C64
Debugger source code? Beware that it is not going to be that easy as you
think!

First of all I wrote this code just for entertainment. That means what it
means, most of code has been developed around 4:30am, on Saturday night
just after I came back from a party, being completely drunk. Oh yes,
that's what I call entertainment... and that's why some ideas in the code
are... strange :) Some people like to play games on their PS4s, I like to
play a game called C++. Ahh, and I do big files, huge files that have 10k
lines of code and store functionality are my drawback. I do not like
mouse clicking, simple paging down or searching method name is quicker
than using mouse to select other files. It is bad, I KNOW. Plus lot of
copy pasting. It is bad, I KNOW.

Code is based on my very old game engine called MTEngine. Origins are
dated back to year 2002 when I developed first lines of code for Nokia
Symbian and created MobiTracker (a mobile XM tracker). The engine was
extended and aimed for mobile apps around 2008 where MobiTracker X for
iPad/Android was born. It has never been released anyway due to lack of
interest from potential users.

Engine is heavy weight, huge and even when I removed most of code for the
C64 Debugger code release it still has drawbacks and limitations due to
quite old mobile technology we had in the year 2009. The engine has been
ported to desktop operating systems many years ago and it is now a base
for the C64 Debugger.

Why I hadn't selected SDL or other engines? Simply speaking, I know my
engine quite well and did not have time to sit and re-implement things in
SDL from scratch. But you're welcome and can do this yourself.


* How to compile sources

What's the biggest pain in the ass is a fact that this project does not
have Makefiles. Simply speaking, because in year 2009 I was not able to
find any Makefile delivery system that was fully multi platform - that
is, that could generate Makefile for Xcode iOS, Android Eclipse, Xcode
MacOS, Linux and Windows VS 2008 C++, and in the year 2009. Thus, the
project files are very related to selected IDEs and I'm compiling this
directly from IDEs. Yes, I'm aware that nowadays we have nice Makefile
generators, but I did not have time to focus and rewrite that part.
What's more, all project files are stored in one source-tree, they are
not organised into libraries as they normally should be. This is due to
the same as above - I wasn't able to properly generate libs in some of
OSes to which I targeted back in '09 so I simply put all files into one
project. It is bad, I KNOW. Besides that, it works for me as-is now, it's
very clumsy, but it works. There are hundreds of files and they compile
quite long time on some of my build machines, but my MBP, a main
development machine, compiles whole project from clean to run in just few
seconds, so this is not an issue for me. And I like that rule you know,
if it works and is quick then why bother. Remember that IS entertainment
coding at sunrise after Saturday's crazy parties :)

I really look forward to get help and create proper Makefiles for the C64
Debugger. I tried this once with CMake but I was stuck with problems how
to handle *.mm files as C++ source code.

Okay, let's go through platforms first.

MacOS: 
This is my main development machine. Just start Xcode, compile and run.
Should work as-is without troubles. Just put files into
~/develop/MTEngine folder.

Linux: 
I use a tool from hell to compile the project that is called Eclipse CDT.
It is crap and you can find my stupid posts on Eclipse support forums
showing why I think so. Devs of Eclipse have never released a stable
version even though it is more than 10 years old. I selected Eclipse
because I wasn't able to find any other IDE for Linux that had proper
wrapper to GDB back in '07. My bad. Should have selected Vi, Emacs or
something. I was able to compile the project on Ubuntu 12.04 recently.
You need to install these libs: gcc, g++, libgtk-3-dev, libasound2-dev,
mesa-common-dev, libglu1-mesa-dev, libglib2.0-dev

Then go to Eclipse settings and make *.mm files compile as C++ source
code: Window/Properties/File types: *.mm as C++ source 

Some of includes can point to ~/develop/MTEngine folder directly, so it's
better that you put the source files there. Note, that project adds
includes to all folders with code.

Windows: 
Code is compatible only with Visual Studio 2008 C++. I was not able to
port the code to newest VS due to bugs and issues in VS itself. Maybe you
know the solution and can help here... the problem is that new VS is not
able to compile *.mm files as C++ code. You can find people that are
moaning about this on StackOverflow, discussing some workarounds, but all
workarounds described there did not work for me. So we are stuck with
Visual Studio 2008 for now due to this. One of solutions is to rename all
*.mm files to *.cpp and remove ObjC dependencies in MacOS part of code.

Remember to have glext.h handy and OpenGL libs. The engine uses also
Pthreads lib that can be got from here: 
https://www.sourceware.org/pthreads-win32/   
a static version of library is being used, so you will need to compile
this lib from source code because they provide only dynamic versions.
Note that you need to compile Pthreads lib from command line, not VS IDE.

In VS2008 C++ you need to set in settings that *.mm files are treated as
C++ code. Note that some paths may point directly to C:\develop\MTEngine,
so just remember to put files in that folder.


Of course you can contact me if you have questions how to compile this
project. It is doable, just a bit clumsy.


* Source code files

The project itself is divided into Engine, platforms-related and Game
folders. It is a bit messy, but this is due to the fact that some IDEs
made by devils from hell can't organise files as they should, so often
some strange things are just there as-is workarounds. The same implies to
the code itself, you'll definitely find places in code that look strange,
like variables that are set to themselves - these are workarounds for
Win32 compiler mostly, which (politely speaking) is stupid and has
errors... Oh yes, sleepless nights, entertainment coding to find that in
assembly code generated by Win32 compiler some important C++ lines were
"forgotten"... normal thing, believe me:) it is called "optimisations
done by Microsoft" :D remove some lines here and there, we have faster
code, less binary size and it does not matter that it does not work, hehe
:D

The Engine folder contains things related to generic UI, resource
manager, tools, etc.

The C64 Debugger code itself is located in Game/c64 folder. Connection to
emulator is achieved via interface, in Game/c64/DebugInterface you will
find an abstract interface with empty methods. This is your starting
point if you would like to add another emulator.

In Game/c64/Emulators you will find Vice. It is a version quite modified
by me that supports features delivered by the debugger. I started from
Vice 2.4 SDL Linux version and removed most of SDL code that was replaced
by hooks to the C64 Debugger - however as you will see, the SDL port from
Vice is still there, just mostly commented out. I left the original SDL
code for now temporarily to not jump between projects too much when I do
research how things are done in Vice. If you'd like to learn yourself, a
Game/c64/Emulators/vice/ViceInterface/ folder is a good starting point.


Okay. Happy fighting with the code. Feel free to contact me if you need
assistance.

SLAJEREK/SAMAR
slajerek@gmail.com

Bialystok, Poland, 2016/06/04
