# Failure Log

This document tracks every production failure encountered during this project.
Each entry includes root cause analysis and the exact fix applied.

> "The only real mistake is the one from which we learn nothing." — Henry Ford

---

<!-- Entries will be added as failures occur -->

## PREVENTIVE-001: Swap configurado en EC2 t3.micro

**Fecha:** 2026-03-21
**Tipo:** Decisión preventiva — no fue un fallo, evita uno futuro

### Contexto
EC2 t3.micro con 914MB RAM corriendo dos servicios Docker:
- InvoiceTrack (~440MB en uso)
- n8n (estimado ~200-300MB adicionales)
Margen disponible sin swap: ~180MB — insuficiente para picos de LLM.

### Riesgo sin swap
Sin swap, un pico de memoria durante procesamiento LLM haría
que el kernel matara el proceso más costoso silenciosamente —
sin log claro, sin alerta. InvoiceTrack o n8n morirían sin aviso.

### Solución aplicada
1GB swapfile en /swapfile, activado y persistido en /etc/fstab.

### Señal de alerta futura
Si `free -h` muestra swap en uso constantemente → señal de que
necesitamos optimizar memoria o migrar a t3.small.

### Comandos aplicados
```bash
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```
