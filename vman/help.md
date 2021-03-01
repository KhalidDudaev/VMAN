
<style>
.bold {font-weight: bold}
.black {color: black }
.red {color: red }
.green {color: green }
.yellow {color: yellow }
.blue {color: blue }
.magenta {color: magenta }
.cyan {color: cyan }
.white {color: white }

.gray {color: gray }
.lred {color: lred }
.lgreen {color: lgreen }
.lyellow {color: lyellow }
.lblue {color: lblue }
.lmagenta {color: lmagenta }
.lcyan {color: lcyan }
.lwhite {color: lwhite }
</style>


Tool for program version manage.  
Selecting the program version from the list of versions.  

syntax:  
   VMAN [command{: .yellow} [group [version]]  
            |        |        |  
            |        |     Program version.  
            |        |        
            |     The name of the software groups managed by VMan.  
            |  
   ----- commands ----------------------------------------------------------------------------------  
   h, help                 Display help  info.                                                       
   v                       Show VMan version.  
   init                    Initialization of a new group of program versions under control of VMan.  
   l, list                 Lists of program groups managed by VMan.                                 
   -------------------------------------------------------------------------------------------------

EXAMPLES:  
   1. Show a list of available program versions  
       VMAN perl  
   2. Selecting the program version from the list of versions  
       VMAN perl 5.32.0.1  

