Show -Width 300 -Height 150 {
   DockPanel {
      Menu -DockPanel-Dock Top -Height 20 {
         MenuItem -Header "_File" {
            ## Hook up the "New" menuitem to the New command ...
            MenuItem -Header "_New" -Command ([system.windows.input.applicationcommands]::new)
            MenuItem -Header "_Open"
            MenuItem -Header "_Save"
            MenuItem -Header "Save _As"
            Separator
            MenuItem -Header "_Print"
            Separator
            MenuItem -Header "E_xit"
         }
         MenuItem -Header "_Edit" {
            MenuItem -Header "_Undo"
            Separator
            MenuItem -Header "Cu_t"
            MenuItem -Header "_Copy"
            MenuItem -Header "_Paste"
            MenuItem -Header "De_lete"
            Separator
            MenuItem -Header "_Find"
            MenuItem -Header "Find _Next"
            MenuItem -Header "_Replace"
            MenuItem -Header "_Go To"
            Separator
            MenuItem -Header "Select _All"
            MenuItem -Header "Time/_Date"
            
         }
         MenuItem -Header "F_ormat" {
            MenuItem -Header "_Word Wrap"
            MenuItem -Header "_Font"
         }
         MenuItem -Header "_View" {
            MenuItem -Header "_Status Bar"
         }
         MenuItem -Header "_Help" {
            MenuItem -Header "_About"
         }
      }
      
      TextBox -Name "Content"
   }
   
   
   ## Down here you can hook up command bindings as usual...
   $this.CommandBindings.Add( (
      CommandBinding -Command ([system.windows.input.applicationcommands]::new) `
                  -On_CanExecute { param($sender, $e) $e.CanExecute = $true }   `
                  -On_Executed { (Select-UIElement $this Content).Text = ""; } 
   ) ) | Out-Null
}

