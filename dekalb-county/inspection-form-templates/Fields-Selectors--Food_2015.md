# Food_2015 Template: Fields & Selectors

| Field               | CSS Selector                                               | Comments |
|---------------------|------------------------------------------------------------|----------|
| Establishment Name  | .ArialEleven:nth-child(3) .borderBottom                    |
| Address             | :nth-child(4) .borderBottom                                |
| City                | .borderRightBottom .ArialEleven:nth-child(1) :nth-child(2) |
| Time In (H)         | .ArialEleven:nth-child(1) :nth-child(4)                    |
| Time In (M)         | .ArialEleven:nth-child(1) :nth-child(6)                    |
| Time In (AM/PM)     | :nth-child(7) b                                            |
| Time Out (H)        | .borderBottom:nth-child(9)                                 |
| Time Out (M)        | .borderBottom:nth-child(11)                                |
| Time Out (AM/PM)    | :nth-child(12) b                                           |
| Inspection Date     | .borderBottom strong                                       |
| CFSM                | .ArialEleven:nth-child(2) :nth-child(6)                    |
| Purpose of Inspection / Risk Type | .ArialTen img                                | Array of 8 circles - Purpose of Inspection Routine/Followup/Initial/Issued Provisional Permit/Temporary & Risk Type 1/2/3 |
| Current Score       | #div_finalScore                                            | |
| Permit #            | .ArialTen .borderBottom                                    | |
