param(
	[string]$OutputDirectory = "Audio\GoalFX"
)

$sampleRate = 44100
$profiles = @(
	@{ Name = "classic_burst"; Duration = 1.05; Base = 72.0; Accent = 230.0; Cutoff = 390.0; Sweep = -24.0; Pulses = 1; Noise = 0.22; Seed = 1101 },
	@{ Name = "andromeda_collapse"; Duration = 1.35; Base = 55.0; Accent = 165.0; Cutoff = 270.0; Sweep = -31.0; Pulses = 2; Noise = 0.20; Seed = 1102 },
	@{ Name = "goal_rush"; Duration = 0.92; Base = 82.0; Accent = 285.0; Cutoff = 460.0; Sweep = -18.0; Pulses = 2; Noise = 0.18; Seed = 1103 },
	@{ Name = "confetti_cup"; Duration = 1.10; Base = 76.0; Accent = 360.0; Cutoff = 520.0; Sweep = -12.0; Pulses = 4; Noise = 0.14; Seed = 1104 },
	@{ Name = "ember_burst"; Duration = 1.16; Base = 63.0; Accent = 215.0; Cutoff = 330.0; Sweep = -28.0; Pulses = 3; Noise = 0.28; Seed = 1105 },
	@{ Name = "electric_net"; Duration = 0.98; Base = 78.0; Accent = 430.0; Cutoff = 590.0; Sweep = -42.0; Pulses = 5; Noise = 0.17; Seed = 1106 },
	@{ Name = "touchline_cyclone"; Duration = 1.28; Base = 59.0; Accent = 180.0; Cutoff = 300.0; Sweep = 18.0; Pulses = 2; Noise = 0.34; Seed = 1107 },
	@{ Name = "pixel_break"; Duration = 0.94; Base = 86.0; Accent = 320.0; Cutoff = 490.0; Sweep = -8.0; Pulses = 5; Noise = 0.12; Seed = 1108 },
	@{ Name = "crown_burst"; Duration = 1.30; Base = 61.0; Accent = 196.0; Cutoff = 340.0; Sweep = -16.0; Pulses = 3; Noise = 0.15; Seed = 1109 },
	@{ Name = "ice_breaker"; Duration = 1.02; Base = 74.0; Accent = 390.0; Cutoff = 560.0; Sweep = -30.0; Pulses = 4; Noise = 0.16; Seed = 1110 },
	@{ Name = "comet_strike"; Duration = 1.24; Base = 58.0; Accent = 260.0; Cutoff = 420.0; Sweep = -55.0; Pulses = 2; Noise = 0.27; Seed = 1111 },
	@{ Name = "trophy_lift"; Duration = 1.34; Base = 65.0; Accent = 220.0; Cutoff = 360.0; Sweep = -10.0; Pulses = 3; Noise = 0.13; Seed = 1112 },
	@{ Name = "stadium_roar"; Duration = 1.38; Base = 52.0; Accent = 150.0; Cutoff = 250.0; Sweep = 9.0; Pulses = 4; Noise = 0.38; Seed = 1113 }
)

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

foreach ($profile in $profiles) {
	$duration = [double]($profile.Duration)
	$sampleCount = [int][Math]::Ceiling($sampleRate * $duration)
	$samples = [double[]]::new($sampleCount)
	$random = [System.Random]::new([int]($profile.Seed))
	$noiseState = 0.0
	$cutoffAlpha = [Math]::Min(0.12, 2.0 * [Math]::PI * [double]($profile.Cutoff) / $sampleRate)
	$peak = 0.0

	for ($index = 0; $index -lt $sampleCount; $index++) {
		$time = $index / [double]$sampleRate
		$normalizedTime = $time / $duration
		$attack = 1.0 - [Math]::Exp(-70.0 * $time)
		$decay = [Math]::Exp(-3.8 * $normalizedTime)
		$phase = 2.0 * [Math]::PI * ([double]($profile.Base) * $time + 0.5 * [double]($profile.Sweep) * $time * $time)
		$body = [Math]::Sin($phase) * 0.52
		$body += [Math]::Sin($phase * 1.48 + 0.35) * 0.16

		$rawNoise = $random.NextDouble() * 2.0 - 1.0
		$noiseState += $cutoffAlpha * ($rawNoise - $noiseState)
		$whoosh = $noiseState * [double]($profile.Noise)

		$pulseLayer = 0.0
		$pulseCount = [int]($profile.Pulses)
		for ($pulseIndex = 0; $pulseIndex -lt $pulseCount; $pulseIndex++) {
			$pulseStart = 0.035 + $pulseIndex * ($duration * 0.48 / [Math]::Max(1, $pulseCount - 1))
			$pulseTime = $time - $pulseStart
			if ($pulseTime -ge 0.0) {
				$pulseEnvelope = [Math]::Exp(-34.0 * $pulseTime)
				$pulseFrequency = [double]($profile.Accent) * (1.0 - 0.08 * $pulseIndex)
				$pulseLayer += [Math]::Sin(2.0 * [Math]::PI * $pulseFrequency * $pulseTime) * $pulseEnvelope * 0.23
			}
		}

		$tail = [Math]::Sin(2.0 * [Math]::PI * ([double]($profile.Base) * 0.52) * $time) * [Math]::Exp(-2.4 * $normalizedTime) * 0.18
		$value = ($body + $whoosh) * $attack * $decay + $pulseLayer + $tail
		$endFade = [Math]::Min(1.0, ($duration - $time) / 0.045)
		$value *= [Math]::Max(0.0, $endFade)
		$samples[$index] = $value
		$peak = [Math]::Max($peak, [Math]::Abs($value))
	}

	$normalization = if ($peak -gt 0.0001) { 0.70 / $peak } else { 1.0 }
	$outputPath = Join-Path $OutputDirectory ("goal_fx_{0}.wav" -f $profile.Name)
	$stream = [System.IO.File]::Open($outputPath, [System.IO.FileMode]::Create)
	$writer = [System.IO.BinaryWriter]::new($stream)
	try {
		$dataSize = $sampleCount * 2
		$writer.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
		$writer.Write([uint32](36 + $dataSize))
		$writer.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))
		$writer.Write([System.Text.Encoding]::ASCII.GetBytes("fmt "))
		$writer.Write([uint32]16)
		$writer.Write([uint16]1)
		$writer.Write([uint16]1)
		$writer.Write([uint32]$sampleRate)
		$writer.Write([uint32]($sampleRate * 2))
		$writer.Write([uint16]2)
		$writer.Write([uint16]16)
		$writer.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
		$writer.Write([uint32]$dataSize)
		foreach ($sample in $samples) {
			$pcm = [int16][Math]::Round([Math]::Max(-1.0, [Math]::Min(1.0, $sample * $normalization)) * 32767.0)
			$writer.Write($pcm)
		}
	}
	finally {
		$writer.Dispose()
		$stream.Dispose()
	}
}

Write-Output ("Generated {0} normalized goal FX sounds in {1}." -f $profiles.Count, $OutputDirectory)
