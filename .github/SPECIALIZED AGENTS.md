# SPECIALIZED AGENTS

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
