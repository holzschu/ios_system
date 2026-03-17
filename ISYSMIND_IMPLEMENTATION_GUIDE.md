# iSysMind Core Implementation Guide

## Quick Start

### Step 1: Directory Structure
```
isysmind/
├── config/
│   └── config.yaml              # Configuration (API keys, thresholds)
├── core/
│   ├── __init__.py
│   ├── ai_router.py             # AI model selection logic
│   ├── system_analyzer.py       # System metrics collection
│   ├── context_manager.py       # Conversation state persistence
│   └── shortcuts_bridge.py      # iOS Shortcuts integration
├── utils/
│   ├── __init__.py
│   ├── logger.py                # Logging configuration
│   ├── cache_manager.py         # Response caching
│   └── config_loader.py         # YAML config loading
├── main.py                      # Entry point
└── requirements.txt             # Python dependencies
```

### Step 2: Install Dependencies
```bash
pip install psutil>=5.9.0 requests>=2.28.0 pyyaml>=6.0 colorama>=0.4.6
```

### Step 3: Configure API Keys
Edit `isysmind/config/config.yaml`:
```yaml
api_keys:
  groq:
    key: "your-actual-groq-api-key"
    enabled: true
  gemini:
    key: "your-actual-gemini-api-key"
    enabled: true
```

---

## Module Reference

### 1. AI Router (`ai_router.py`)

**Purpose:** Intelligently select AI model based on query complexity and system resources

**Main Classes:**
- `QueryComplexityAnalyzer`: Analyze query for complexity markers
- `AIRouter`: Route queries to optimal model

**Usage Example:**
```python
from isysmind.core.ai_router import AIRouter
from isysmind.core.system_analyzer import SystemAnalyzer

# Initialize
config = load_config()  # Load from config.yaml
system_analyzer = SystemAnalyzer(config)
router = AIRouter(config, system_metrics_provider=system_analyzer.get_metrics)

# Route a query
query = "How do I optimize Python code?"
result = router.route(query)

print(f"Selected model: {result.selected_model.value}")
print(f"Complexity score: {result.complexity_score}/100")
print(f"Confidence: {result.confidence:.2%}")
print(f"Timeout: {result.timeout_seconds}s")
print(f"Reasoning: {result.reasoning}")

# Record performance
response_time_ms = 2340
router.record_completion(result.selected_model, response_time_ms, success=True)
```

**Key Features:**
- Complexity scoring: 0-100 scale
- Multi-factor decision: complexity + resources + preferences
- Resource-aware downgrading: Lower power consumption when battery/CPU critical
- Performance tracking: Historical stats for each model

**Decision Matrix:**
```
Complexity Score 0-30     → Groq (fast, low power)
Complexity Score 31-65    → Gemini (balanced)
Complexity Score 66-100   → DeepSeek R1 (expert reasoning)

If battery < 20% or CPU > 80% → Downgrade to faster model
```

---

### 2. System Analyzer (`system_analyzer.py`)

**Purpose:** Safely collect and normalize system metrics within iOS sandbox

**Main Classes:**
- `SystemMetrics`: Data class for normalized metrics
- `SystemAnalyzer`: Collects CPU, RAM, battery data

**Usage Example:**
```python
from isysmind.core.system_analyzer import SystemAnalyzer

config = load_config()
analyzer = SystemAnalyzer(config)

# Get current metrics
metrics = analyzer.get_metrics(use_cache=True)

print(f"CPU: {metrics.cpu_percent}%")
print(f"Memory: {metrics.memory_percent}% ({metrics.memory_available_mb}MB free)")
print(f"Battery: {metrics.battery_percent}% ({metrics.battery_status})")
print(f"Device: {metrics.device_type} running iOS {metrics.ios_version}")

# Check resource status
if metrics.is_low_resources():
    print("WARNING: Critical resource shortage!")
elif metrics.is_constrained_resources():
    print("INFO: Resources constrained, use lighter models")

# Get recommendations
recommendations = analyzer.get_resource_recommendations()
for category, message in recommendations.items():
    print(f"{category}: {message}")
```

**Metrics Provided:**
- `cpu_percent`: CPU usage (0-100%)
- `memory_percent`: RAM usage (0-100%)
- `memory_available_mb`: Free RAM in MB
- `battery_percent`: Battery level (0-100%) or None
- `battery_status`: "unknown", "low", "charging", "full"
- `device_type`: "iphone", "ipad", "unknown"
- `ios_version`: iOS version string
- `is_simulator`: Boolean

**Data Collection Strategy:**
```
Method 1 (Preferred): psutil library
├── Most reliable in a-Shell
└── Returns complete metrics

Method 2 (Fallback): Parse /proc filesystem
├── /proc/stat for CPU
├── /proc/meminfo for memory
└── /proc/battery for battery (limited)

Method 3 (Last Resort): System commands
├── uname, pmset
└── Graceful degradation if unavailable
```

**Caching:**
- 5-second TTL by default (configurable)
- Reduces overhead while maintaining freshness
- Useful for rapid queries

---

### 3. Data Flow Integration

**Query to Response Flow:**
```
User Query
    ↓
System Analyzer.get_metrics()
    ↓ (CPU, RAM, Battery)
AI Router.route(query, metrics)
    ↓ (Complexity analysis)
Select Model (Groq/Gemini/DeepSeek)
    ↓
Load API Key from config
    ↓
API Call with timeout
    ↓ (Success)
Parse Response
    ↓
Context Manager.update_history()
    ↓
Cache Response (if offline mode)
    ↓
Format & Display Output
    ↓
Record Performance Stats
    ↓
User Response
```

---

### 4. Configuration Integration

**Loading Configuration:**
```python
import yaml
from pathlib import Path

def load_config():
    config_path = Path(__file__).parent / "config" / "config.yaml"
    with open(config_path) as f:
        return yaml.safe_load(f)

config = load_config()

# Access nested config
groq_key = config["api_keys"]["groq"]["key"]
timeout = config["router"]["timeout_gemini"]
```

**Configuration Sections:**
- `api_keys`: API authentication
- `router`: Model selection thresholds and timeouts
- `system_analyzer`: Metric collection settings
- `shortcuts`: iOS Shortcuts configuration
- `context`: Conversation history management
- `offline`: Caching and offline behavior
- `ui`: Output formatting
- `logging`: Debug settings
- `performance`: Optimization tuning
- `advanced`: Experimental features

---

## Error Handling

### API Errors
```python
import requests

try:
    response = make_api_call(model, query, timeout=30)
except requests.Timeout:
    logger.error("API timeout, trying alternative model")
    result = router.route(query, force_model=fallback_model)
except requests.HTTPError as e:
    if e.response.status_code == 429:
        logger.error("Rate limited, backing off")
        time.sleep(60)
    elif e.response.status_code == 401:
        logger.error("Invalid API key for " + model.value)
```

### Resource Constraints
```python
metrics = analyzer.get_metrics()

if metrics.battery_percent and metrics.battery_percent < 10:
    logger.warning("Critical battery, aborting complex operations")
    return "Battery critical - please charge device"

if metrics.memory_percent > 90:
    logger.warning("Memory exhausted, switching to cache mode")
    return cache_similar_query(query)
```

### Offline Mode
```python
try:
    response = call_api(query)
except requests.ConnectionError:
    logger.info("Offline mode activated")
    cached = cache_manager.find_similar(query)
    if cached:
        return f"[CACHED] {cached['response']}"
    else:
        return "No internet connection and no cached response available"
```

---

## Testing

### Unit Tests for AI Router
```python
import unittest
from isysmind.core.ai_router import QueryComplexityAnalyzer, AIRouter

class TestComplexityAnalyzer(unittest.TestCase):
    def setUp(self):
        self.analyzer = QueryComplexityAnalyzer()
    
    def test_simple_query(self):
        result = self.analyzer.analyze("What is Python?")
        self.assertLess(result.total_score, 30)
    
    def test_complex_query(self):
        result = self.analyzer.analyze("""
        Design a red-black tree with O(log n) insertion
        while maintaining balance properties and handling
        concurrent access through fine-grained locking
        """)
        self.assertGreater(result.total_score, 65)
    
    def test_code_blocks(self):
        result = self.analyzer.analyze("""
        How do I optimize this code?
        ```python
        for i in range(1000000):
            result += expensive_operation(i)
        ```
        """)
        self.assertTrue(result.has_code_blocks)
```

### Unit Tests for System Analyzer
```python
class TestSystemAnalyzer(unittest.TestCase):
    def setUp(self):
        self.analyzer = SystemAnalyzer()
    
    def test_metrics_valid_range(self):
        metrics = self.analyzer.get_metrics(use_cache=False)
        self.assertGreaterEqual(metrics.cpu_percent, 0)
        self.assertLessEqual(metrics.cpu_percent, 100)
        self.assertGreaterEqual(metrics.memory_percent, 0)
        self.assertLessEqual(metrics.memory_percent, 100)
    
    def test_caching(self):
        metrics1 = self.analyzer.get_metrics(use_cache=True)
        metrics2 = self.analyzer.get_metrics(use_cache=True)
        self.assertEqual(metrics1.timestamp, metrics2.timestamp)
    
    def test_device_detection(self):
        device = self.analyzer._detect_device_type()
        self.assertIn(device, ["iphone", "ipad", "unknown"])
```

---

## Performance Considerations

### Optimization Tips
1. **Caching**: Default 5-second TTL on metrics
2. **Lazy imports**: Load heavy libraries only when needed
3. **Async support**: Design for future async/await refactor
4. **Connection pooling**: Reuse HTTP connections
5. **Response compression**: Compress cached responses

### Profiling
```python
import cProfile
import pstats
import io

pr = cProfile.Profile()
pr.enable()

# Run your code
result = router.route(query)

pr.disable()
s = io.StringIO()
ps = pstats.Stats(pr, stream=s).sort_stats('cumulative')
ps.print_stats(10)  # Top 10 functions
print(s.getvalue())
```

---

## Debugging

### Enable Debug Logging
```python
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

router = AIRouter(config)  # Will now log debug info
analyzer = SystemAnalyzer(config)
```

### Common Issues

**Issue: "psutil not available"**
- Install: `pip install psutil`
- Fallback to /proc parsing is automatic

**Issue: "API key not found"**
- Check config.yaml has actual key, not placeholder
- Check env variable: `export GROQ_API_KEY="..."`

**Issue: "No battery data"**
- Expected in a-Shell sandbox
- Use system_metrics.battery_percent == None check

**Issue: "High latency on complex queries"**
- DeepSeek R1 can take 30-60 seconds
- Check timeout_deepseek in config
- Consider reducing context size

---

## Next Steps

This implementation provides:
✓ Production-ready AI routing logic
✓ Safe system metric collection
✓ Comprehensive error handling
✓ Configuration flexibility
✓ Performance tracking
✓ iOS sandbox compatibility

**For Phase 2 (Implementation):**
- [ ] Implement `context_manager.py` (conversation persistence)
- [ ] Implement `shortcuts_bridge.py` (iOS integration)
- [ ] Build `api_client.py` (API calls to Groq/Gemini/DeepSeek)
- [ ] Create `cache_manager.py` (offline support)
- [ ] Develop CLI interface (`main.py`)
- [ ] Write comprehensive tests
