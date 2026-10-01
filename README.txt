ADAPTIVE 1V1 GENERATION WORKFLOW

1) BEFORE the current evaluation/promotions overwrite active.json, run:
   .\training\freeze_current_1v1_reference.ps1

2) Let the current evaluation finish completely.

3) Collect the entire run + champion/archive state:
   .\training\collect_1v1_generation_results.ps1 -RunId 20260810_212113

4) Upload the generated file:
   1v1_generation_20260810_212113_results.zip

Do NOT start another blind 3-hour generation before reviewing these results.
The next generation should be targeted to the actual weaknesses of the promoted champion.
