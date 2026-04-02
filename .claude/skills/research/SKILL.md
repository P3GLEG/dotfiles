---
name: research
description: Launch a deep research investigation on any topic. Decomposes the question, runs parallel subagents with Exa and Brave Search, cross-references findings, and produces a cited markdown report. Use when the user wants thorough research, competitive analysis, literature review, or technology evaluation.
argument-hint: "<topic to research> [--mode quick|standard|deep] [--domain tech|academic|general]"
---
# Deep Research: $ARGUMENTS

## Instructions

You are initiating a deep research workflow. Follow these steps precisely:

### Step 1: Parse the request
Extract from the arguments:
- **Topic**: The main research question or topic
- **Mode**: quick (3 searches, ~2 min), standard (default, 5 subagents, ~5-10 min), or deep (5 subagents + verification, ~10-20 min)
- **Domain**: tech, academic, or general (auto-detect if not specified)

### Step 2: Create output directory
```bash
mkdir -p research-output
```

### Step 3: Delegate to the research-orchestrator agent
Use the research-orchestrator agent to conduct the full research workflow. Pass it the topic, mode, and domain. The orchestrator will:
1. Decompose the question into sub-questions
2. Spawn parallel researcher subagents (web-researcher, code-researcher, or academic-researcher as appropriate)
3. Synthesize findings into a comprehensive report
4. Write the report to `research-output/YYYY-MM-DD-<topic-slug>.md`
5. Return a terminal summary

### Step 4: Confirm completion
After the orchestrator finishes, display:
- The file path of the saved report
- The terminal summary (top 3-5 key findings)
- Total sources consulted
