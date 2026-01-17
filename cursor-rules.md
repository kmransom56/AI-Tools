# Cursor Agent Rules & Standards

**Based on your AGENTS.md - Reorganized for Cursor IDE**  
**Date**: 2026-01-16  
**Version**: 1.0

---

# CORE RULES & STANDARDS

## Code Quality & Standards

### Python Standards
- **Package Manager**: Always use `uv` for Python dependency management
- **Code Formatting**: Use `black` with line length 88
- **Linting**: Flake8 with max-line-length=88, ignore E203,W503,E501
- **Target Version**: Python 3.12+
- **No Copy-Paste**: All file modifications must be automated using tools

### Mandatory Quality Checks
Run these IN ORDER after any code change:
```bash
# 1. Format
black app/ tests/ tools/ *.py

# 2. Lint
flake8 app/ tests/ tools/ --max-line-length=88 --ignore=E203,W503,E501

# 3. Syntax check
python -m py_compile app/**/*.py tests/**/*.py tools/**/*.py
```

### File Operations
- **MANDATORY**: Always write files directly using tools - NEVER provide code for manual copy-paste
- Use available file operation tools
- No code blocks for user to copy-paste

### Code Style
- **Framework**: FastAPI for backend development
- **Async/Await**: Use async/await for asynchronous operations
- **Error Handling**: Comprehensive try-except with proper logging

## Port Management Protocol

**CRITICAL**: NEVER guess port numbers!

```bash
# Find available port
port-registry find

# Register port (REQUIRED)
port-registry register $PORT "AppName" "Description"

# Check existing
port-registry list

# Lookup specific port
port-registry lookup $PORT
```

## Docker Workflow

**Always follow this exact sequence**:

1. Stop containers: `docker compose down`
2. Make code changes
3. Run quality checks (black → flake8 → compile)
4. Rebuild: `docker compose up --build -d`
5. Verify: `docker compose logs -f [service]`

**NEVER** skip the rebuild step after code changes!

## Security & Credentials

### Credential Handling
- **NEVER commit credentials** - use environment variables
- Store in `.env` files (gitignored)
- API keys in separate `.env` files by service
- SSH keys in `~/.ssh/` (system-level)

### SSL/TLS
- Support corporate CA certificates (Zscaler compatibility)
- Certificate rotation documented
- HTTPS enforced in production

## Project Context

### Tech Stack
- **Backend**: FastAPI, Python 3.12+
- **Package Management**: uv
- **Containerization**: Docker, Docker Compose
- **Testing**: pytest, Playwright
- **Code Quality**: Black, Flake8

### Network Infrastructure Focus
- Fortinet ecosystem (FortiGate, FortiManager, FortiAP, FortiSwitch)
- Cisco Meraki Dashboard API
- Technitium DNS
- Multi-site enterprise deployments (3,500+ locations)

## Ambition vs Precision

### New Tasks (Brand New Context)
- Be ambitious and creative
- Demonstrate comprehensive implementation
- Show good judgment with extras

### Existing Codebase
- **Surgical precision required**
- Change only what's requested
- Respect existing patterns
- Maintain consistency
- Avoid unnecessary refactoring

---

# TESTING & DOCUMENTATION

## Testing Requirements

### Before Committing
- Run full quality check (black, flake8, compile)
- All tests must pass
- Coverage: Aim for 80%+

### E2E Testing
- Use Playwright for end-to-end tests
- Tests in `tests/e2e/`
- Name files with `.spec.js` or `.spec.ts`

## Documentation Requirements

### Required Documentation
- API endpoints documented (OpenAPI/Swagger)
- Setup and deployment guides
- Architecture decisions (ADRs) for major changes
- Troubleshooting guides
- README with quick-start

### Code Documentation
- Module docstrings explaining purpose
- Function signatures with type hints
- Complex logic documented inline
- Examples for public APIs

---

# QUICK REFERENCE

## Common Tasks

| Task | Check | Ask Agent |
|------|-------|-----------|
| Create FastAPI endpoint | Rules section | Python Developer |
| Set up Docker | Rules section | DevOps |
| Configure FortiGate | Skills section | Network Infrastructure |
| Create migration | Skills section | Database |
| Write tests | Skills section | Testing & QA |
| Document API | Skills section | Documentation |

## Quality Check Commands

```bash
# Always in this order!
black app/ tests/ tools/ *.py
flake8 app/ tests/ tools/ --max-line-length=88 --ignore=E203,W503,E501
python -m py_compile app/**/*.py tests/**/*.py tools/**/*.py
```

## Port Management

```bash
port-registry find                           # Find available
port-registry register $PORT "Name" "Desc"   # Register (required!)
port-registry list                           # View all
```

## Docker Workflow

```bash
docker compose down                    # Stop
# Make changes + run quality checks
docker compose up --build -d          # Rebuild
docker compose logs -f [service]      # Verify
```

---

# GOLDEN RULES

❌ **NEVER**:
- Copy-paste code (use tools only)
- Hardcode port numbers (use port-registry)
- Commit credentials (use .env)
- Skip quality checks
- Deploy to production without approval

✅ **ALWAYS**:
- Use `uv` for Python packages
- Run: black → flake8 → pytest
- Docker: down → change → checks → up --build
- Register ports with port-registry
- Use environment variables for secrets

---

**Configuration Ready!**  
**Status**: Production Ready  
**Date**: 2026-01-16  
**Version**: 1.0
