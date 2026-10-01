1V1 ELITE RECOVERY V4

Fixes the final blank-ExitCode bug in the PARALLEL worker benchmark queue.

Run from project root:
  .\training\recover_1v1_elite_evaluation.ps1

This reuses run 20260810_212113 and DOES NOT repeat training.
Already completed baseline/worker benchmark JSON files are reused.
A Godot process is considered successful when it wrote valid benchmark JSON,
even when Windows PowerShell exposes a blank ExitCode.
