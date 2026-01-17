# Cursor Agent Configuration - Complete Guide

**Based on your AGENTS.md - Reorganized for Cursor IDE**  
**Date**: 2026-01-16  
**Version**: 1.0  

---

## 📋 How to Use This File

This single file contains your complete Cursor Agent configuration. You can:

1. **Option 1**: Use as-is - Keep this single file as `cursor-rules.md` in your project root
2. **Option 2**: Split into 3 files (recommended):
   - `cursor-rules.md` (sections 1-2)
   - `cursor-skills.md` (section 3)
   - `cursor-subagents.md` (section 4)

Cursor IDE will automatically detect and use these files.

---

# SECTION 1: CORE RULES & STANDARDS

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

# SECTION 2: TESTING & DOCUMENTATION

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

# SECTION 3: AGENT SKILLS & CAPABILITIES

## Built-in Agent Tools

### File Operations
- **Read Files**: Access any file in the codebase
- **Write Files**: Create and modify files
- **Directory Operations**: Navigate and manage directories

### Terminal & Shell
- **Command Execution**: Run shell commands
- **Build & Test**: black, flake8, pytest, docker
- **Environment Management**: Virtual env, uv, port-registry

### Code Generation
- **Function Implementation**: Generate from descriptions
- **Boilerplate Creation**: Create project templates
- **Test Generation**: Write unit and integration tests
- **Documentation**: Create docstrings and guides

## Specialized Network Skills

### Fortinet Device Management
- **FortiGate Configuration**: Parse and generate FortiOS configs
- **FortiManager Integration**: API calls for centralized management
- **Static BGP Configuration**: Manage routing policies
- **FortiAP & FortiSwitch**: Wireless and switching configs

### Cisco Meraki Integration
- **Dashboard API**: Query networks, devices, events
- **Organization Management**: Manage Meraki orgs and admins
- **Device Configuration**: Update device settings and policies
- **Network Monitoring**: Real-time metrics and alerts

### DNS & Security
- **Technitium DNS**: Configuration and query management
- **DNSCrypt Implementation**: Secure DNS setup
- **RADIUS Integration**: Authentication server configs
- **Certificate Management**: PKI and SSL/TLS operations

### Network Topology & Visualization
- **3D Force-Graph**: Generate network topology visualizations
- **Device Discovery**: Scan and identify network devices
- **Topology Mapping**: Create visual representations
- **Dependency Analysis**: Map service and device relationships

### Multi-Site Management
- **Site Inventory**: Manage 3,500+ location configurations
- **Batch Operations**: Bulk changes across sites
- **Configuration Sync**: Synchronize configs across locations
- **Compliance Checking**: Verify standard configurations

## Development Skills

### Python FastAPI
- **API Endpoint Creation**: Generate REST endpoints
- **Request/Response Handling**: Parse and format API payloads
- **Async Operations**: Create async functions and handlers
- **Error Handling**: Implement proper exception handling

### Docker & Containerization
- **Dockerfile Generation**: Create optimized Docker images
- **Docker Compose Setup**: Multi-service configuration
- **Volume Management**: Persistent data configuration
- **Network Configuration**: Container networking

### Testing & Quality
- **Unit Test Generation**: Create pytest test files
- **Integration Testing**: Setup test fixtures and mocks
- **E2E Testing**: Generate Playwright test scenarios
- **Coverage Analysis**: Calculate and improve code coverage

### Database Operations
- **SQL Queries**: Write and optimize SQL
- **Schema Migrations**: Create database migrations
- **ORM Models**: Define SQLAlchemy models
- **Data Import/Export**: Handle data transformation

## Analytics & Debugging

### Code Analysis
- **Bug Detection**: Identify logical errors and edge cases
- **Performance Analysis**: Find bottlenecks
- **Security Scanning**: Identify vulnerabilities
- **Code Duplication**: Find and eliminate duplicate code

### System Diagnostics
- **Health Checks**: Run system verification scripts
- **Dependency Analysis**: Check package compatibility
- **Configuration Validation**: Verify config correctness
- **Log Analysis**: Parse and analyze application logs

## Integration Skills

### Git & Version Control
- **Commit Operations**: Create meaningful commits
- **Branch Management**: Create and manage branches
- **Merge Conflict Resolution**: Resolve conflicts intelligently
- **History Analysis**: Use git log and blame for context

### API Integration
- **REST API Calls**: Make authenticated HTTP requests
- **Webhook Handling**: Parse incoming webhooks
- **Rate Limiting**: Implement rate limit awareness
- **Error Retry Logic**: Implement exponential backoff

---

# SECTION 4: SPECIALIZED AGENTS

## Agent Hierarchy

```
Root Agent (Coordinator)
├── Python Developer Agent
├── DevOps & Deployment Agent
├── Network Infrastructure Agent
├── Database & Data Agent
├── Testing & QA Agent
└── Documentation Agent
```

## 1. Python Developer Agent

**Purpose**: Handle Python code development, FastAPI endpoints, and application logic.

### Activation Triggers
- Python file modifications requested
- New FastAPI endpoint creation
- Python package management
- Code quality improvements
- Bug fixes in Python code

### Responsibilities
- Write clean, well-tested Python code
- Implement FastAPI endpoints with proper validation
- Handle async/await patterns correctly
- Follow uv package management conventions
- Maintain black/flake8 compliance
- Write comprehensive docstrings and type hints

### Key Skills
- FastAPI development
- Python code quality (black, flake8)
- Async/await patterns
- pytest unit testing
- Package management with uv

---

## 2. DevOps & Deployment Agent

**Purpose**: Manage infrastructure, Docker, containerization, and deployment workflows.

### Activation Triggers
- Docker/container changes requested
- Deployment configuration needed
- Environment setup required
- Port allocation needed
- Container orchestration tasks

### Responsibilities
- Create and optimize Dockerfiles
- Manage docker-compose configurations
- Port allocation via port-registry
- Environment variable management
- Health check implementation
- Monitoring and alerting configuration

### Key Skills
- Docker and docker-compose
- Port registry management
- Environment configuration
- Deployment automation
- Health checks and monitoring

---

## 3. Network Infrastructure Agent

**Purpose**: Handle Fortinet, Meraki, DNS, and network topology management.

### Activation Triggers
- FortiGate/FortiManager configuration
- Meraki Dashboard API calls
- DNS (Technitium) management
- Network topology visualization
- Device discovery and inventory
- Multi-site network management

### Responsibilities
- Parse and generate FortiOS configurations
- Execute Meraki Dashboard API operations
- Manage Technitium DNS records
- Create network topology visualizations
- Discover and catalog network devices
- Manage multi-site deployments (3,500+ locations)

### Key Skills
- Fortinet ecosystem (FortiGate, FortiManager, FortiAP, FortiSwitch)
- Cisco Meraki Dashboard API
- Technitium DNS management
- Network topology visualization (3D force-graph)
- Device discovery and inventory
- BGP and routing configuration
- RADIUS and certificate management

---

## 4. Database & Data Agent

**Purpose**: Manage databases, migrations, data processing, and analytics.

### Activation Triggers
- Database schema changes
- Migration creation needed
- Data import/export operations
- Query optimization required
- Data validation/cleaning

### Responsibilities
- Create database migrations
- Write and optimize SQL queries
- Implement data transformations
- Handle data import/export
- Perform data validation
- Manage database backups
- Create analytics reports

### Key Skills
- SQL query writing and optimization
- Database migrations (Alembic)
- Data processing (Pandas)
- Backup and restore procedures
- Analytics and reporting

---

## 5. Testing & QA Agent

**Purpose**: Create tests, validate quality, and ensure reliability.

### Activation Triggers
- New test creation requested
- Code quality checks needed
- E2E testing required
- Regression testing
- Coverage analysis

### Responsibilities
- Write unit tests (pytest)
- Create integration tests
- Generate E2E tests (Playwright)
- Calculate code coverage
- Perform regression testing
- Create test fixtures and mocks

### Key Skills
- pytest framework
- Playwright E2E testing
- Coverage analysis
- Test fixtures and mocking
- Performance testing
- Regression testing

---

## 6. Documentation Agent

**Purpose**: Create and maintain all documentation.

### Activation Triggers
- Documentation updates needed
- API documentation generation
- User guide creation
- Architecture decision documentation
- Troubleshooting guide updates

### Responsibilities
- Generate API documentation (OpenAPI/Swagger)
- Write user guides and tutorials
- Create architecture documentation
- Document architectural decisions (ADRs)
- Update README and setup guides
- Write troubleshooting guides

### Key Skills
- Markdown documentation
- OpenAPI/Swagger generation
- Architecture diagramming
- User guide writing
- ADR (Architecture Decision Record) creation

---

## Agent Capabilities Matrix

| Task Type | Python Dev | DevOps | Network | Database | Testing | Docs |
|-----------|-----------|--------|---------|----------|---------|------|
| FastAPI Development | ⭐⭐⭐ | - | - | ⭐ | ⭐⭐⭐ | ⭐⭐ |
| Docker Setup | ⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐ | ⭐ |
| Network Config | - | ⭐⭐ | ⭐⭐⭐ | - | ⭐ | ⭐⭐ |
| Database Schema | ⭐⭐ | ⭐ | - | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| Testing | ⭐⭐ | ⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐ |
| Documentation | ⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐ | ⭐⭐⭐ |
| Bug Fixing | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ |

**Legend**: ⭐⭐⭐ = Primary, ⭐⭐ = Secondary, ⭐ = Support, - = Not involved

---

## Escalation Paths

### When Agents Escalate to User
- **Security Issues**: Potential vulnerabilities detected
- **Architecture Decisions**: Major structural changes needed
- **Production Changes**: Deployment to production requested
- **Policy Violations**: Conflicts with project standards
- **Ambiguity**: Task requirements unclear
- **Blocked**: Dependencies or permissions needed

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

Save this as `cursor-rules.md` in your project root and Cursor IDE will automatically use it!
