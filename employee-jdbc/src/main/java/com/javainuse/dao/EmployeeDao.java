package com.javainuse.dao;

import java.util.List;

import com.javainuse.model.Employee;

public interface EmployeeDao {
	List<Employee> getAllEmployees();

	void insertEmployee(Employee employee);
}